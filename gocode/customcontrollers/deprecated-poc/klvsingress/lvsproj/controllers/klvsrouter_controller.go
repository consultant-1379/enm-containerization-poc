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
	// "k8s.io/apiextensions-apiserver/pkg/controller/status"
	"fmt"
	// "k8s.io/apimachinery/pkg/runtime/schema"
	"bytes"
	"errors"
	"reflect"
	"strconv"

	"context"
	"github.com/go-logr/logr"
	corev1 "k8s.io/api/core/v1"
	apierrs "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	// "k8s.io/apimachinery/pkg/types"
	// metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"

	routersv1 "com.ericsson.oss.microservices/lvsrouter/api/v1"
	"os/exec"
	// "sigs.k8s.io/controller-runtime/pkg/handler"
	// "time"
	// "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

// KlvsRouterReconciler reconciles a KlvsRouter object
type KlvsRouterReconciler struct {
	client.Client
	Log    logr.Logger
	Scheme *runtime.Scheme
}

/*
We generally want to ignore (not requeue) on NotFound errors, since we’ll get a reconcile
request once the object becomes found, and requeuing in the mean time won’t help
*/
func ignoreNotFound(err error) error {
	if apierrs.IsNotFound(err) {
		return nil
	}
	return err
}

// func Watch(&source.Kind{Type: &routersv1.Klvsrouter{}}, &handler.EnqueueRequestForObject{}) {
// 	// _ = context.Background()
// 	// _ = r.Log.WithValues("router-watcher", req.NamespacedName)

// 	ctx := context.Background()
// 	log := r.Log.WithValues("klvsrouter", req.NamespacedName)
// 	log.Info("watch watch watch....",ctx)

// 	return ctrl.Result{}, nil
// }

// +kubebuilder:rbac:groups=routers.lvsrouter.ericsson.com,resources=klvsrouters,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=routers.lvsrouter.ericsson.com,resources=klvsrouters/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=,resources=services,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=,resources=pods,verbs=get;list;watch;create;update;patch;delete
func (r *KlvsRouterReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	// _ = context.Background()
	// _ = r.Log.WithValues("klvsryyouter", req.NamespacedName)

	ctx := context.Background()
	log := r.Log.WithValues("klvsrouter", req.NamespacedName)

	log.Info("Hey hey hey")
	// log.Info("Sleeping")
	// time.Sleep(5 * time.Second)

	// // your logic here
	// // _ = ctx.Done

	var klvsrouter routersv1.KlvsRouter

	if err := r.Get(ctx, req.NamespacedName, &klvsrouter); err != nil {
		log.Error(err, "unable to fetch KlvsRouter")
		// we'll ignore not-found errors, since they can't be fixed by an immediate
		// requeue (we'll need to wait for a new notification), and we can get them
		// on deleted requests.
		return ctrl.Result{}, ignoreNotFound(err)
	}

	log.Info("NS:", req.Name, klvsrouter.ObjectMeta.Namespace)
	log.Info("IP", req.Name, klvsrouter.Spec.Vip)
	log.Info("Name", req.Name, klvsrouter.Spec.Service.Name)
	log.Info("Ports", req.Name, klvsrouter.Spec.Service.ServiceMappings)
	log.Info("Ports", req.Name, klvsrouter.Spec.Service.Endpoints)

	mystatus := klvsrouter.Status.Active

	//************** THROWS ERROR **********************
	// if _, err := DoStuff("abdul"); err != nil {
	// 	return ctrl.Result{}, err

	// }

	command, _ := RunCommand("boo")
	fmt.Println("Command result: ", command)

	protocol := "-t"
	vip := "10.32.184.5"
	lbPort := 84
	sch := "rr"

	fmt.Println("running command...........")
	executeIpvsadm("-A", protocol, vip+":"+strconv.Itoa(lbPort), "-s", sch)

	fmt.Println("mystatus: ", mystatus)
	fmt.Println("doing stuff, marking done: ", mystatus)
	// klvsrouter.Status.Active=1
	// klvsrouter.Status.Complete=1
	// fmt.Println("All marked..............")
	mystatus2 := klvsrouter.Status.Active
	fullstatus := klvsrouter.Status
	fmt.Println("fullstatus: ", fullstatus)

	if mystatus2 == 1 {
		fmt.Println("doing stuff, setting status to 0")
		klvsrouter.Status.Active = 0
	} else {
		fmt.Println("doing stuff, setting status to 1")
		klvsrouter.Status.Active = 1
	}

	fmt.Println("mystatus2: ", mystatus2)

	fmt.Println("lets pretend something went wrong and call reconcile again: ", mystatus2)
	var localcontext = context.TODO()
	fmt.Println("localcontext: ", localcontext)

	// err := r.Update(context.TODO(), &klvsrouter)
	// if err != nil{
	// 	fmt.Println("%s\n", err)
	// 	return ctrl.Result{},err
	// }
	//return reconcile.Result{},err}

	// for i, lvsrouter := range klvsrouter.Items {
	// 	status =lvsrouter.Status.Active

	// }

	var service corev1.Service

	//

	//  ns :=klvsrouter.metav1.ObjectMeta.Namespace
	// service := &corev1.Service{}
	// service := corev1.Service
	// c is a created client.
	if err := r.Get(ctx, client.ObjectKey{Namespace: klvsrouter.ObjectMeta.Namespace, Name: klvsrouter.Spec.Service.Name}, &service); err != nil {
		log.Error(err, "unable to fetch service")
		return ctrl.Result{}, nil
	}

	log.Info("ServObj", req.Name, service.Spec)

	//get endpoints list -- all endpoints
	eplist := &corev1.EndpointsList{}
	if err := r.List(ctx, eplist); err != nil {
		log.Error(err, "unable to fetch eplist")
		return ctrl.Result{}, nil
	}

	// for e := eplist.endpointinstance; e != nil; e = e.Next() {
	// 	fmt.Println(e.Value) // print out the elements
	// }

	// log.Info("Retrieved eplist:", eplist)
	// can't range over eplists
	// for k := range eplist.Items {
	// 	// log.Info("KEY:", k)
	// 	fmt.Println("key:", k)

	// }
	fmt.Println("********************************************")

	fmt.Println("EndpointsListmeta", eplist.ListMeta)
	// fmt.Println("EndpointsListmeta", eplist.Endpoints)
	for i, endpoint := range eplist.Items {

		if endpoint.Namespace == klvsrouter.ObjectMeta.Namespace && endpoint.Name == "kubernetes" {
			fmt.Println("TYPE of endpoint:>>>>>>>>>", reflect.TypeOf(endpoint))
			fmt.Println("endpoint found at index:", i)
			fmt.Println("Namespace:", endpoint.Namespace)
			fmt.Println("Name:", endpoint.Name)
			fmt.Println("Meta:", endpoint.ObjectMeta)
			// fmt.Println("Subset:", endpoint.Subsets.EndpointAddress)

			var sub = endpoint.Subsets
			for i, element := range sub {
				fmt.Println("i:>>>>>>>>>", i)
				fmt.Println("element addresses:>>>>>>>>>", element.Addresses)
				fmt.Println("element addresses:>>>>>>>>>", element.Addresses)

				var addresses = element.Addresses
				for x, address := range addresses {
					fmt.Println("x:>>>>>>>>>", x)
					fmt.Println("address:>>>>>>>>>", address.IP)

				}
				fmt.Println("TYPE of item:>>>>>>>>>", reflect.TypeOf(element))
			}
			// for a, item := range sub {}
			// fmt.Println("Subset:", endpoint.EndpointSubset)

			// fmt.Println("Subset:", endpoint.addresses)
			// fmt.Println("Subset:", endpoint.MetaData)

			// fmt.Println("Meta:", endpoint.EndpointAddress)
			// fmt.Println("Meta:", endpoint.ObjectMeta.Spec)
			// fmt.Println("Meta:", endpoint.ObjectMeta.Ports)
			// fmt.Println("Meta:", endpoint.ObjectMeta.IP)
			// fmt.Println("endpoint:", endpoint.subsets)
		}

	}
	fmt.Println("********************************************")

	fmt.Println("*************UNSTRUCTURED SEARCH*******************************")
	// get unstructerd object endpoint list
	// u := &unstructured.UnstructuredList{}
	// u.SetGroupVersionKind(schema.GroupVersionKind{
	// 	Group:   "core",
	// 	Kind:    "Endpoints",
	// 	Version: "v1",
	// })

	// if err := r.List(ctx, u); err != nil {
	// 	log.Error(err, "unable to fetch unstructured list")
	// 	return ctrl.Result{}, nil
	// }
	// for index, element := range u.Items {
	// 	fmt.Println("index", index)
	// 	fmt.Println("element:", element)

	// }
	fmt.Println("*************UNSTRUCTURED SEARCH OVER*******************************")

	fmt.Println("*************filtered search******************************")

	/**
	BELOW SEARCH USING COREV1.ENDPOINTS IS SOLUTION!
	BELOW will retireve all Endpoints for a given service
	*/

	// var endpointList corev1.EndpointsList
	var endpoints corev1.Endpoints
	if err := r.Get(ctx, client.ObjectKey{Namespace: klvsrouter.ObjectMeta.Namespace, Name: klvsrouter.Spec.Service.Name}, &endpoints); err != nil {
		log.Error(err, "unable to fetch endpoints: ")
		return ctrl.Result{}, nil
	}

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
		var ports = element.Ports
		for x, port := range ports {
			fmt.Println("x:>>>>>>>>>", x)
			fmt.Println("port:>>>>>>>>>", port.Port)
			fmt.Println("Name:>>>>>>>>>", port.Name)

		}
		fmt.Println("TYPE of item:>>>>>>>>>", reflect.TypeOf(element))
	}

	// var endpointsSubsets corev1.Endpoints.Subsets
	// if err := r.Get(ctx, client.ObjectKey{Namespace: klvsrouter.ObjectMeta.Namespace, Name: klvsrouter.Spec.BackendService.Name}, &endpointsSubsets); err != nil {
	// 	log.Error(err, "unable to fetch endpointsSubsets: ")
	// 	return ctrl.Result{}, nil
	// }

	// for a, endpointx := range endpointList {

	// 	fmt.Println("a:>>>>>>>>>", a)
	// 	fmt.Println("endpointx>>>>>>>>>", endpointx)
	// }

	// fmt.Println("*************FILTERED SEARCH*******************************")
	// 	//get endpoint lis t
	// 	eplist2 := &corev1.EndpointsList{}
	// 	if err := r.List(ctx, client.ObjectKey{"namespace": "default", "name": "tcpserver"}, eplist2); err != nil {
	// 		log.Error(err, "unable to fetch eplist2")
	// 		return ctrl.Result{}, nil
	// 	}

	//client.ObjectKey{Namespace: klvsrouter.ObjectMeta.Namespace, Name: klvsrouter.Spec.BackendService.Name}

	// for _, endpointinstance := range(endpoints){
	// 	log.Info("EPs", req.Name, endpointinstance.Spec)

	// }
	// log.Info("EPs", req.Name, endpoints.endpoints)

	// // os := &corev1.Service{}
	// pod := &corev1.Pod{}

	// log.Info("ServObj", req.Name, service.Spec)

	// // Check if the Service already exists
	// foundService := &corev1.Service{}
	// err := r.Get(ctx, types.NamespacedName{Name: "tcpserver", Namespace: "default"}, foundService)
	// if err != nil {
	// 	// log.Printf("Creating Service %s/%s\n", service.Namespace, service.Name)
	// 	// err = r.Create(context.TODO(), service)
	// 	log.Info("YAhoottttoo", req.Name, foundService.Spec)
	// 	if err != nil {
	// 		return ctrl.Result{}, err
	// 	}
	// } else if err != nil {
	// 	return ctrl.Result{}, err
	// }
	// log.Info("YAhooooooo", req.Name, foundService.Spec)

	//getting services
	// var childJobs kbatch.JobList
	// if err := r.List(ctx, &service, client.InNamespace(req.Namespace), client.MatchingField("Name", "tcpserver")); err != nil {
	// 	log.Error(err, "unable to list child Service")
	// 	return ctrl.Result{}, err
	// }

	// if err := r.List(ctx, &pod, client.InNamespace(req.Namespace), client.MatchingField("Name", "demo-controller-74589f948b-5ctm9")); err != nil {
	// 	log.Error(err, "unable to list child Service")
	// 	return ctrl.Result{}, err
	// }

	// if err := r.Get(ctx, req.NamespacedName, &service); err != nil {
	// 	log.Error(err, "unable to fetch simple serv")
	// 	// we'll ignore not-found errors, since they can't be fixed by an immediate
	// 	// requeue (we'll need to wait for a new notification), and we can get them
	// 	// on deleted requests.
	// 	return ctrl.Result{}, ignoreNotFound(err)
	// }

	// pod := &corev1.Pod{}
	// c is a created client.
	// _ = c.Get(context.Background(), client.ObjectKey{
	// 	Namespace: "default",
	// 	Name:      "tecpserver",
	// }, service)

	// log.Info("pod", req.Name, pod.Spec)

	return ctrl.Result{}, nil
}

// /*
// Brians attempted refactoring
// */
// func (r *KlvsRouterReconciler) GetResources(namespace string, name string , endpoints corev1.Endpoints){

// 	if err := r.Get(ctx, client.ObjectKey{Namespace: knamespace, Name: name}, objectReference); err != nil {
// 		r.Log.Error(err, "unable to fetch objects for name: ")
// 		return ctrl.Result{}, nil
// 	}

// }

func DoStuff(param string) (string, error) {

	if param == "boo" {
		return "waaaaaaaaaaaa", nil
	} else {
		return "", errors.New("Brians error")
	}

}

func RunCommand(param string) ([]byte, error) {

	fmt.Println("Running command...")

	// cmd := exec.Command("sleep", "1")
	cmd := exec.Command("ipvsadm", "-A -t 192.168.0.31:80 -s wlc")
	fmt.Println("Running command and waiting for it to finish...")
	if err := cmd.Run(); err != nil {
		fmt.Println("Command finished with error:", err)
	}
	return cmd.CombinedOutput()

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

func (r *KlvsRouterReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&routersv1.KlvsRouter{}).
		Complete(r)
}
