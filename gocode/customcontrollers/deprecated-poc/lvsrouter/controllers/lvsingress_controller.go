/*

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	enmv1 "_/mnt/c/gocode/lvsrouter/api/v1"
	"bytes"
	"context"
	"fmt"
	"os/exec"
	"strconv"
	"strings"

	corev1 "k8s.io/api/core/v1"

	"github.com/go-logr/logr"
	apierrs "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
)

// LvsIngressReconciler reconciles a LvsIngress object
type LvsIngressReconciler struct {
	client.Client
	Log    logr.Logger
	scheme *runtime.Scheme
}

func ignoreNotFound(err error) error {
	if apierrs.IsNotFound(err) {
		return nil
	}
	return err
}

// IPPort ip:port
type IPPort struct {
	IP   string
	Port string
}

// Reconcile CRD object
// +kubebuilder:rbac:groups=enm.lvsrouter,resources=lvsingresses,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=enm.lvsrouter,resources=lvsingresses/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=,resources=services,verbs=get;list;watch;update;patch;delete
func (r *LvsIngressReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	ctx := context.TODO()
	log := r.Log.WithValues("lvsingress", req.NamespacedName)

	var instance enmv1.LvsIngress

	if err := r.Get(ctx, req.NamespacedName, &instance); err != nil {
		log.Error(err, "unable to fetch LvsIngress")

		return ctrl.Result{}, ignoreNotFound(err)

	}

	// if instance.Status.Total = 4; instance.Status.Active <= instance.Status.Total {
	// 	instance.Status.Active++
	// }
	// if err := r.Update(context.TODO(), &instance); err != nil {
	// 	log.Error(err, "unable to update status LvsIngress")
	// 	return ctrl.Result{}, ignoreNotFound(err)
	// }

	log.Info("Reconciling LVS Ingress", req.Name, instance.Spec)

	vip := instance.Spec.VirtualServiceIP
	endpoints := corev1.Endpoints{}
	if err := r.Get(ctx, client.ObjectKey{Namespace: instance.ObjectMeta.Namespace, Name: instance.Spec.BackendService.ServiceName}, &endpoints); err != nil {
		log.Error(err, "unable to fetch LvsIngress endpoints")

		return ctrl.Result{}, ignoreNotFound(err)
	}
	portMappings := instance.Spec.BackendService.PortMappings
	epSubsets := endpoints.Subsets

	for _, pm := range portMappings {
		svcPort := pm.SvcPort
		lbPort := pm.LbPort
		protocol := "-t"
		if !strings.EqualFold("TCP", pm.Protocol) {
			protocol = "-u"
		}
		//adding a virtual service with the VI

		virtualService := IPPort{
			IP:   vip,
			Port: strconv.Itoa(lbPort),
		}

		if !checkVirtualServiceExists(virtualService, protocol) {
			fmt.Println("running command ... ipvsadm -A " + protocol + " " + vip + ":" + strconv.Itoa(lbPort) + " -s " + pm.Sch)
			executeIpvsadm("-A", protocol, vip+":"+strconv.Itoa(lbPort), "-s", pm.Sch)
		} else {
			fmt.Println("virtual service already existing")
		}

		for _, ep := range epSubsets {
			addresses := ep.Addresses
			for _, address := range addresses {

				realBackend := IPPort{
					IP:   address.IP,
					Port: strconv.Itoa(svcPort),
				}

				ipvsadmAdd(virtualService, realBackend, protocol)
				fmt.Println("address endpoint ", address.IP+":"+strconv.Itoa(svcPort)+" LB Port"+strconv.Itoa(lbPort))
			}
		}

	}
	/*
		fmt.Println("TYPE of item:>>>>>>>>>", reflect.TypeOf(endpoints))
		var sub = endpoints.Subsets
		for i, element := range sub {
			fmt.Println("i:>>>>>>>>>", i)
			fmt.Println("element addresses:>>>>>>>>>", element.Addresses)

			var addresses = element.Addresses
			for x, address := range addresses {
				fmt.Println("x:>>>>>>>>>", x)
				fmt.Println("address:>>>>>>>>>", address.IP)

			}
			fmt.Println("TYPE of item:>>>>>>>>>", reflect.TypeOf(element))
		}

		fmt.Println("Iterating Through portMappings:>>>>>>>>>")
		portMappings := instance.Spec.BackendService.PortMappings
		for _, lbport := range portMappings {

			cmd := exec.Command("ipvsadm", "-Ln", "-t", instance.Spec.VirtualServiceIP+":"+strconv.Itoa(lbport.LbPort))
			var out bytes.Buffer
			cmd.Stdout = &out

			if err := cmd.Run(); err != nil {
				fmt.Println("ipvsadm command error", err)
			} else {
				instance.Spec.BackendService.ServiceEndPoints = out.String()
				if err := r.Update(context.TODO(), &instance); err != nil {
					fmt.Println("failed to update CRD", out.String())
				}
				fmt.Println("ipvsadm output", out.String())
			}

		}
	*/
	return ctrl.Result{}, nil
}

func checkVirtualServiceExists(virtualService IPPort, protocol string) bool {
	vs := virtualService.IP + ":" + virtualService.Port

	cmd := exec.Command("ipvsadm", "-L", protocol, vs)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	cmd.Stdout = &stdout

	if err := cmd.Run(); err != nil {
		fmt.Println("ipvsadm command failed error", stderr.String())
		return false
	}
	fmt.Println("ipvsadm output", stdout.String())
	return true
}

func checkBackendServiceExists(backendService IPPort, protocol string) bool {
	bs := backendService.IP + ":" + backendService.Port

	cmd := exec.Command("ipvsadm", "-L", protocol, bs, "|", "grep", bs)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	cmd.Stdout = &stdout

	if err := cmd.Run(); err != nil {
		fmt.Println("ipvsadm command failed error", stderr.String())
		return false
	}
	fmt.Println("ipvsadm output", stdout.String())
	return true
}

func ipvsadmAdd(virtualService IPPort, realBackend IPPort, protocol string) {
	executeIpvsadm("-a", protocol, virtualService.IP+":"+virtualService.Port, "-r", realBackend.IP+":"+realBackend.Port, "-m")
}

func ipvsadmRemove(virtualService IPPort, realBackend IPPort) {

}

func executeIpvsadm(args ...string) {
	cmd := exec.Command("ipvsadm", args...)
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stderr = &stderr
	cmd.Stdout = &stdout

	if err := cmd.Run(); err != nil {
		fmt.Println("ipvsadm command failed error", stderr.String())
	}
	fmt.Println("ipvsadm output", stdout.String())
}

//SetupWithManager in main.go
func (r *LvsIngressReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).For(&enmv1.LvsIngress{}).Complete(r)
}
