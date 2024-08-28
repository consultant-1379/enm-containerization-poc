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

	routingv1alpha1 "gerrit.ericsson.se/oss/com.ericsson.oss.containerisation/enm-container-poc/gocode/customcontrollers/lvsingress/api/v1alpha1"
)

//IPVS and Misc constants
const (
	ipvsadmCommand       string = "ipvsadm"
	minusA               string = "-a"
	minusD               string = "-d"
	minusM               string = "-m"
	minusR               string = "-r"
	minusS               string = "-s"
	minusCapitalA               = "-A"
	minusCapitalD               = "-D"
	minusCapitalLn              = "-Ln"
	colon                       = ":"
	lvsIngressLabelKey          = "lvsingress"
	modified                    = "modified"
	endpointModification        = "endpointModification"
	serviceNotFound             = "serviceNotFound"
)

var k Keepalived

// LvsIngressReconciler reconciles a LvsIngress object
type LvsIngressReconciler struct {
	client.Client
	Keepalived Keepalived
	Log        logr.Logger
	scheme     *runtime.Scheme
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
// +kubebuilder:rbac:groups=routing.lvsingress.ericsson.com,resources=lvsingresses,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=routing.lvsingress.ericsson.com,resources=lvsingresses/status,verbs=get;update;patch
func (r *LvsIngressReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	ctx := context.TODO()
	log := r.Log.WithValues("lvsingress", req.NamespacedName)

	var ingressCrd routingv1alpha1.LvsIngress

	if err := r.Get(ctx, req.NamespacedName, &ingressCrd); err != nil {
		log.Error(err, "unable to fetch LvsIngress, does not exist, ignoring")

		return ctrl.Result{}, ignoreNotFound(err)

	}

	log.Info("Reconciling LVS Ingress", req.Name, ingressCrd.Spec)

	// alreadyReconciled := ingressCrd.Spec.Event.Reconciled

	// if alreadyReconciled {

	// 	ReconcileModification(req,ingressCrd,ctx,log)

	// } else {

	vip := ingressCrd.Spec.VirtualServiceIP
	endpoints := corev1.Endpoints{}
	svc := corev1.Service{}

	if !k.Started {

		if err := k.configureKeepalived(r.Client); err != nil {
			fmt.Println("===============could not configure keepalived ======= ")
		}

		fmt.Println("configured keepalived")
		k.Start()
		go k.HandleSigterm(k)
		k.Started = true
	}

	//retrieve the svc associated with the ingress
	if err := r.Get(ctx, client.ObjectKey{Namespace: ingressCrd.ObjectMeta.Namespace, Name: ingressCrd.Spec.BackendService.ServiceName}, &svc); err != nil {
		log.Error(err, "unable to fetch LvsIngress backend service, please create it....")
		//return err as we want to automatically try and fix this, it will be requeued

		DeleteVirtualService(ingressCrd, log)
		// r.CleanUpCrd(ingressCrd)
		return ctrl.Result{}, err
	}

	//retrieve the endpoints. revisit why ignoreNotFound()
	if err := r.Get(ctx, client.ObjectKey{Namespace: ingressCrd.ObjectMeta.Namespace, Name: ingressCrd.Spec.BackendService.ServiceName}, &endpoints); err != nil {
		log.Error(err, "unable to fetch LvsIngress endpoints")
		return ctrl.Result{}, ignoreNotFound(err)
	}

	portMappings := ingressCrd.Spec.BackendService.PortMappings
	epSubsets := endpoints.Subsets
	// existingEndpointAddresses := ingressCrd.Spec.BackendService.EndpointAddresses

	// if len(existingEndpointAddresses) == 0{
	// 	log.Info("No Endpoint addresses found on CRD, configuring rules for first time", req.Name, "")
	// 	 //Clean up IPVS if old config exists
	// 	 //*********ROUGH APPROACH IDEALLY SHOULD JUST
	// 	 DeleteVirtualService(ingressCrd, log)
	// }

	//delete the service and build again
	DeleteVirtualService(ingressCrd, log)

	// var addresses [5]corev1.EndpointAddress{}
	addresses := make([]corev1.EndpointAddress, 0)
	//for every port mappings create a virtual service vith vip and port
	for _, pm := range portMappings {
		svcPort := pm.SvcPort
		lbPort := pm.LbPort
		protocol := "-t"
		if !strings.EqualFold("TCP", pm.Protocol) {
			protocol = "-u"
		}
		//adding a virtual service with the VIP

		virtualService := IPPort{
			IP:   vip,
			Port: strconv.Itoa(lbPort),
		}
		ipvsadmAddVirtualService(virtualService, protocol, pm.Sch)
		fmt.Println("running command ... ipvsadm -A " + protocol + " " + vip + ":" + strconv.Itoa(lbPort) + " -s " + pm.Sch)

		//for every endpoint add backend
		for _, ep := range epSubsets {
			// addresses := ep.Addresses
			addresses = ep.Addresses
			for _, address := range addresses {

				realBackend := IPPort{
					IP:   address.IP,
					Port: strconv.Itoa(svcPort),
				}

				ipvsadmAddBackend(virtualService, realBackend, protocol)
				fmt.Println("address endpoint ", address.IP+":"+strconv.Itoa(svcPort)+" LB Port"+strconv.Itoa(lbPort))
			}
		}
		// add metadata to endpoints object this links the endpoint to a CRD
		//crdMeta :=  req.Name
		//endpoints.ObjectMeta.Annotations.
		// annotations := endpoint.ObjectMeta.Annotations

	}

	//set service ServiceEndpoints on LvsIngress
	fmt.Println("Setting ServiceEndpoints on LvsIngress", addresses)
	// ingressCrd.Spec.BackendService.EndpointAddresses = addresses
	// // ingressCrd.Spec.Event.Reconciled=true
	// // ingressCrd.Status.RequiresReconciliation=false

	// if err := r.Update(context.TODO(), &ingressCrd); err != nil{

	// 	log.Error(err, "Error updating ingressCrd.Spec.BackendService.ServiceEndPoints on initial reconcile on LvsIngress")
	// 	return ctrl.Result{}, ignoreNotFound(err)
	// }

	//label the Endpoints object with the CRD name
	// labels := endpoints.ObjectMeta.Labels
	serviceLabels := svc.ObjectMeta.Labels

	if len(serviceLabels) == 0 {
		fmt.Println("No labels exist on Service, initialising map")
		serviceLabels = make(map[string]string)

	}
	//Set the label, this labels service and endpoints
	// SetServiceLabel(&serviceLabels, &req)
	//move this part to func too
	serviceLabels[lvsIngressLabelKey] = req.Name
	svc.ObjectMeta.Labels = serviceLabels
	//update the resource
	if err := r.Update(context.TODO(), &svc); err != nil {

		log.Error(err, "Error updating Service label")
		return ctrl.Result{}, ignoreNotFound(err)
	}

	// ingressCrd.Spec.Event.Reconciled=true
	return ctrl.Result{}, nil
}

// func SetServiceLabel(labels *map[string]string, req *ctrl.Request){

// 	if len(*labels) == 0{
// 		fmt.Println("No labels exist on Service, initialising map")
// 		*labels = make(map[string]string)

// 	}

// 	*labels[lvsIngressLabelKey] = req.Name

// }

//ReconcileModification Reconcile a modification on an existing CRD
// func ReconcileModification(req ctrl.Request, ingressCrd routingv1alpha1.LvsIngress, ctx context.Context, log logr.Logger) (ctrl.Result, error) {

// 	log.Info("Reconciling LVS Ingress Modification", req.Name, ingressCrd.Spec)
// 	event := ingressCrd.Spec.Event
// 	eventEndpointAddresses := event.EndpointAddresses
// 	crdEndpointAddresses := ingressCrd.Spec.BackendService.EndpointAddresses
// 	action := event.Action
// 	fmt.Println("Event: ",event)
// 	fmt.Println("crdEndpointAddresses: ",crdEndpointAddresses)
// 	log.Info("action: {}, endppint: {}",string(action),eventEndpointAddresses)
// 	return ctrl.Result{}, nil
// }

/*

 */
func ipvsadmAddBackend(virtualService IPPort, realBackend IPPort, protocol string) {
	cmd := exec.Command(ipvsadmCommand, minusA, protocol, virtualService.IP+colon+virtualService.Port, minusR, realBackend.IP+colon+realBackend.Port, minusM)
	out, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println("ipvsadm command failed error", err)
	}
	fmt.Println("ipvsadm output", string(out))

}

func ipvsadmRemoveBackend(virtualService IPPort, realBackend IPPort, protocol string) {
	cmd := exec.Command(ipvsadmCommand, minusD, protocol, virtualService.IP+colon+virtualService.Port, minusR, realBackend.IP+colon+realBackend.Port)
	out, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println("ipvsadm command failed error", err)
	}
	fmt.Println("ipvsadm output", string(out))
}

func ipvsadmAddVirtualService(virtualService IPPort, protocol string, sch string) {
	cmd := exec.Command(ipvsadmCommand, minusCapitalA, protocol, virtualService.IP+colon+virtualService.Port, minusS, sch)
	out, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println("ipvsadm command failed error", err)
	}
	fmt.Println("ipvsadm output", string(out))

}

//SetupWithManager in main.go
func (r *LvsIngressReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&routingv1alpha1.LvsIngress{}).
		Complete(r)
}

//DeleteVirtualService Generate ipvsadm commands to delete virtual services
func DeleteVirtualService(ingressCrd routingv1alpha1.LvsIngress, log logr.Logger) {

	portMappings := ingressCrd.Spec.BackendService.PortMappings
	vip := ingressCrd.Spec.VirtualServiceIP
	// backendService := ingressCrd.Spec.BackendService
	// var emptyPortMappings []routingv1alpha1.PortMappings
	// backendService.PortMappings = emptyPortMappings
	// var emptyEndpointAddresses []corev1.EndpointAddress
	// backendService.EndpointAddresses = emptyEndpointAddresses

	// 	// var addresses [5]corev1.EndpointAddress{}
	// addresses := make([]corev1.EndpointAddress,0)
	//for every port mappings create a virtual service vith vip and port
	for _, pm := range portMappings {
		// svcPort := pm.SvcPort
		lbPort := pm.LbPort
		protocol := "-t"
		if !strings.EqualFold("TCP", pm.Protocol) {
			protocol = "-u"
		}

		//delete the virtual service
		virtualService := IPPort{
			IP:   vip,
			Port: strconv.Itoa(lbPort),
		}
		fmt.Println("Constructing delete command for :" + virtualService.IP + colon + virtualService.Port)
		IpvsadmDeleteVirtualService(virtualService, protocol, log)
		// fmt.Println("running command ... ipvsadm -A " + protocol + " " + vip + ":" + strconv.Itoa(lbPort) + " -s " + pm.Sch)
		// log.Info("Reconciling LVS Ingress", req.Name, ingressCrd.Spec)
		log.Info("Deleted backend service (if existed)", vip, strconv.Itoa(lbPort))
	}

}

// //IpvsadmDeleteVirtualService delete the virtualservice
func IpvsadmDeleteVirtualService(virtualService IPPort, protocol string, log logr.Logger) {

	if CheckVirtualServiceExists(virtualService, protocol, log) {
		cmd := exec.Command(ipvsadmCommand, minusCapitalD, protocol, virtualService.IP+colon+virtualService.Port)
		fmt.Println("Deleting using command " + ipvsadmCommand + " " + minusCapitalD + " " + protocol + " " + virtualService.IP + colon + virtualService.Port)
		out, err := cmd.CombinedOutput()
		if err != nil {
			log.Error(err, "ipvsadm delete virtual servicecommand failed error")
		}
		log.Info("ipvsadm delete virtual servicecommand completed", "output", string(out))
	}

}

func CheckVirtualServiceExists(virtualService IPPort, protocol string, log logr.Logger) bool {

	//ipvsadm -D -t 10.10.20.30:8080
	cmd := exec.Command(ipvsadmCommand, minusCapitalLn, protocol, virtualService.IP+colon+virtualService.Port)
	// fmt.Println("Deleting using command "+ipvsadmCommand+" "+minusCapitalD+" "+protocol+" "+virtualService.IP+colon+virtualService.Port);
	out, err := cmd.CombinedOutput()
	if err != nil {
		log.Error(err, "Virtual Service check exist: false"+virtualService.IP+colon+virtualService.Port)
		return false
	}
	log.Info("Virtual Service check exist: true", "output", string(out))
	return true

}

// func (r *LvsIngressReconciler) CleanUpCrd(ingressCrd routingv1alpha1.LvsIngress)(bool, error){

// 	backendService := ingressCrd.Spec.BackendService
// 	// var emptyPortMappings []routingv1alpha1.PortMappings
// 	// backendService.PortMappings = emptyPortMappings
// 	emptyEndpointAddresses := make([]corev1.EndpointAddress,0)
// 	backendService.EndpointAddresses = emptyEndpointAddresses

// 	ingressCrd.Spec.BackendService.EndpointAddresses = backendService.EndpointAddresses
// 	ingressCrd.Spec.Event.Action = modified
// 	ingressCrd.Spec.Event.Description  = serviceNotFound
// 	ingressCrd.Spec.Event.EndpointAddresses = backendService.EndpointAddresses

// 	if err := r.Update(context.TODO(), &ingressCrd); err != nil{

// 		r.Log.Error(err, "Error updating ingressCrd.Spec.BackendService.ServiceEndPoints on initial reconcile on LvsIngress")
// 		return false, ignoreNotFound(err)
// 	}
// 	return true,nil
// }
