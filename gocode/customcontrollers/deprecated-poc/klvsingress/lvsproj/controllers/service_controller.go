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
	// "fmt"
	// "k8s.io/apimachinery/pkg/runtime/schema"
	// "reflect"

	"context"
	"github.com/go-logr/logr"
	corev1 "k8s.io/api/core/v1"
	// apierrs "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/runtime"
	// "k8s.io/apimachinery/pkg/types"
	// metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	// routersv1 "com.ericsson.oss.microservices/lvsrouter/api/v1"
	// "time"
	// "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

// ServiceReconciler reconciles a Kubernetes object
type ServiceReconciler struct {
	client.Client
	Log    logr.Logger
	Scheme *runtime.Scheme
}

// /*
// We generally want to ignore (not requeue) on NotFound errors, since we’ll get a reconcile
// request once the object becomes found, and requeuing in the mean time won’t help
// */
// func ignoreNotFound(err error) error {
// 	if apierrs.IsNotFound(err) {
// 		return nil
// 	}
// 	return err
// }

// +kubebuilder:rbac:groups=routers.lvsrouter.ericsson.com,resources=klvsrouters,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=routers.lvsrouter.ericsson.com,resources=klvsrouters/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=,resources=services,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=,resources=pods,verbs=get;list;watch;create;update;patch;delete
func (r *ServiceReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	_ = context.Background()
	_ = r.Log.WithValues("servicecontroller", req.NamespacedName)

	// ctx := context.Background()
	// log := r.Log.WithValues("klvsrouter", req.NamespacedName)

	// log.Info("Hey hey hey")
	// // log.Info("Sleeping")
	// // time.Sleep(5 * time.Second)

	// // // your logic here
	// // // _ = ctx.Done

	// var klvsrouter routersv1.KlvsRouter

	// if err := r.Get(ctx, req.NamespacedName, &klvsrouter); err != nil {
	// 	log.Error(err, "unable to fetch KlvsRouter")
	// 	// we'll ignore not-found errors, since they can't be fixed by an immediate
	// 	// requeue (we'll need to wait for a new notification), and we can get them
	// 	// on deleted requests.
	// 	return ctrl.Result{}, ignoreNotFound(err)
	// }

	// log.Info("NS:", req.Name, klvsrouter.ObjectMeta.Namespace)
	// log.Info("IP", req.Name, klvsrouter.Spec.IP)
	// log.Info("Name", req.Name, klvsrouter.Spec.BackendService.Name)
	// log.Info("Ports", req.Name, klvsrouter.Spec.BackendService.Ports)

	// var service corev1.Service

	// //

	// //  ns :=klvsrouter.metav1.ObjectMeta.Namespace
	// // service := &corev1.Service{}
	// // service := corev1.Service
	// // c is a created client.
	// if err := r.Get(ctx, client.ObjectKey{Namespace: klvsrouter.ObjectMeta.Namespace, Name: klvsrouter.Spec.BackendService.Name}, &service); err != nil {
	// 	log.Error(err, "unable to fetch service")
	// 	return ctrl.Result{}, nil
	// }

	// log.Info("ServObj", req.Name, service.Spec)

	// //get endpoints list -- all endpoints
	// eplist := &corev1.EndpointsList{}
	// if err := r.List(ctx, eplist); err != nil {
	// 	log.Error(err, "unable to fetch eplist")
	// 	return ctrl.Result{}, nil
	// }

	// // for e := eplist.endpointinstance; e != nil; e = e.Next() {
	// // 	fmt.Println(e.Value) // print out the elements
	// // }

	// // log.Info("Retrieved eplist:", eplist)
	// // can't range over eplists
	// // for k := range eplist.Items {
	// // 	// log.Info("KEY:", k)
	// // 	fmt.Println("key:", k)

	// // }
	// fmt.Println("********************************************")

	// fmt.Println("EndpointsListmeta", eplist.ListMeta)
	// // fmt.Println("EndpointsListmeta", eplist.Endpoints)
	// for i, endpoint := range eplist.Items {

	// 	if endpoint.Namespace == klvsrouter.ObjectMeta.Namespace && endpoint.Name == "kubernetes" {
	// 		fmt.Println("TYPE of endpoint:>>>>>>>>>", reflect.TypeOf(endpoint))
	// 		fmt.Println("endpoint found at index:", i)
	// 		fmt.Println("Namespace:", endpoint.Namespace)
	// 		fmt.Println("Name:", endpoint.Name)
	// 		fmt.Println("Meta:", endpoint.ObjectMeta)
	// 		// fmt.Println("Subset:", endpoint.Subsets.EndpointAddress)

	// 		var sub = endpoint.Subsets
	// 		for i, element := range sub {
	// 			fmt.Println("i:>>>>>>>>>", i)
	// 			fmt.Println("element addresses:>>>>>>>>>", element.Addresses)
	// 			fmt.Println("element addresses:>>>>>>>>>", element.Addresses)

	// 			var addresses = element.Addresses
	// 			for x, address := range addresses {
	// 				fmt.Println("x:>>>>>>>>>", x)
	// 				fmt.Println("address:>>>>>>>>>", address.IP)

	// 			}
	// 			fmt.Println("TYPE of item:>>>>>>>>>", reflect.TypeOf(element))
	// 		}
	// 		// for a, item := range sub {}
	// 		// fmt.Println("Subset:", endpoint.EndpointSubset)

	// 		// fmt.Println("Subset:", endpoint.addresses)
	// 		// fmt.Println("Subset:", endpoint.MetaData)

	// 		// fmt.Println("Meta:", endpoint.EndpointAddress)
	// 		// fmt.Println("Meta:", endpoint.ObjectMeta.Spec)
	// 		// fmt.Println("Meta:", endpoint.ObjectMeta.Ports)
	// 		// fmt.Println("Meta:", endpoint.ObjectMeta.IP)
	// 		// fmt.Println("endpoint:", endpoint.subsets)
	// 	}

	// }
	// fmt.Println("********************************************")

	// fmt.Println("*************UNSTRUCTURED SEARCH*******************************")
	// // get unstructerd object endpoint list
	// // u := &unstructured.UnstructuredList{}
	// // u.SetGroupVersionKind(schema.GroupVersionKind{
	// // 	Group:   "core",
	// // 	Kind:    "Endpoints",
	// // 	Version: "v1",
	// // })

	// // if err := r.List(ctx, u); err != nil {
	// // 	log.Error(err, "unable to fetch unstructured list")
	// // 	return ctrl.Result{}, nil
	// // }
	// // for index, element := range u.Items {
	// // 	fmt.Println("index", index)
	// // 	fmt.Println("element:", element)

	// // }
	// fmt.Println("*************UNSTRUCTURED SEARCH OVER*******************************")

	// fmt.Println("*************filtered search******************************")

	// /**
	// BELOW SEARCH USING COREV1.ENDPOINTS IS SOLUTION!
	// BELOW will retireve all Endpoints for a given service
	// */

	// // var endpointList corev1.EndpointsList
	// var endpoints corev1.Endpoints
	// if err := r.Get(ctx, client.ObjectKey{Namespace: klvsrouter.ObjectMeta.Namespace, Name: "kubernetes"}, &endpoints); err != nil {
	// 	log.Error(err, "unable to fetch endpoints: ")
	// 	return ctrl.Result{}, nil
	// }

	// fmt.Println("TYPE of item:>>>>>>>>>", reflect.TypeOf(endpoints))
	// var sub = endpoints.Subsets
	// for i, element := range sub {
	// 	fmt.Println("i:>>>>>>>>>", i)
	// 	fmt.Println("element addresses:>>>>>>>>>", element.Addresses)

	// 	var addresses = element.Addresses
	// 	for x, address := range addresses {
	// 		fmt.Println("x:>>>>>>>>>", x)
	// 		fmt.Println("address:>>>>>>>>>", address.IP)

	// 	}
	// 	fmt.Println("TYPE of item:>>>>>>>>>", reflect.TypeOf(element))
	// }

	// // var endpointsSubsets corev1.Endpoints.Subsets
	// // if err := r.Get(ctx, client.ObjectKey{Namespace: klvsrouter.ObjectMeta.Namespace, Name: klvsrouter.Spec.BackendService.Name}, &endpointsSubsets); err != nil {
	// // 	log.Error(err, "unable to fetch endpointsSubsets: ")
	// // 	return ctrl.Result{}, nil
	// // }

	// // for a, endpointx := range endpointList {

	// // 	fmt.Println("a:>>>>>>>>>", a)
	// // 	fmt.Println("endpointx>>>>>>>>>", endpointx)
	// // }

	// // fmt.Println("*************FILTERED SEARCH*******************************")
	// // 	//get endpoint lis t
	// // 	eplist2 := &corev1.EndpointsList{}
	// // 	if err := r.List(ctx, client.ObjectKey{"namespace": "default", "name": "tcpserver"}, eplist2); err != nil {
	// // 		log.Error(err, "unable to fetch eplist2")
	// // 		return ctrl.Result{}, nil
	// // 	}

	// //client.ObjectKey{Namespace: klvsrouter.ObjectMeta.Namespace, Name: klvsrouter.Spec.BackendService.Name}

	// // for _, endpointinstance := range(endpoints){
	// // 	log.Info("EPs", req.Name, endpointinstance.Spec)

	// // }
	// // log.Info("EPs", req.Name, endpoints.endpoints)

	// // // os := &corev1.Service{}
	// // pod := &corev1.Pod{}

	// // log.Info("ServObj", req.Name, service.Spec)

	// // // Check if the Service already exists
	// // foundService := &corev1.Service{}
	// // err := r.Get(ctx, types.NamespacedName{Name: "tcpserver", Namespace: "default"}, foundService)
	// // if err != nil {
	// // 	// log.Printf("Creating Service %s/%s\n", service.Namespace, service.Name)
	// // 	// err = r.Create(context.TODO(), service)
	// // 	log.Info("YAhoottttoo", req.Name, foundService.Spec)
	// // 	if err != nil {
	// // 		return ctrl.Result{}, err
	// // 	}
	// // } else if err != nil {
	// // 	return ctrl.Result{}, err
	// // }
	// // log.Info("YAhooooooo", req.Name, foundService.Spec)

	// //getting services
	// // var childJobs kbatch.JobList
	// // if err := r.List(ctx, &service, client.InNamespace(req.Namespace), client.MatchingField("Name", "tcpserver")); err != nil {
	// // 	log.Error(err, "unable to list child Service")
	// // 	return ctrl.Result{}, err
	// // }

	// // if err := r.List(ctx, &pod, client.InNamespace(req.Namespace), client.MatchingField("Name", "demo-controller-74589f948b-5ctm9")); err != nil {
	// // 	log.Error(err, "unable to list child Service")
	// // 	return ctrl.Result{}, err
	// // }

	// // if err := r.Get(ctx, req.NamespacedName, &service); err != nil {
	// // 	log.Error(err, "unable to fetch simple serv")
	// // 	// we'll ignore not-found errors, since they can't be fixed by an immediate
	// // 	// requeue (we'll need to wait for a new notification), and we can get them
	// // 	// on deleted requests.
	// // 	return ctrl.Result{}, ignoreNotFound(err)
	// // }

	// // pod := &corev1.Pod{}
	// // c is a created client.
	// // _ = c.Get(context.Background(), client.ObjectKey{
	// // 	Namespace: "default",
	// // 	Name:      "tecpserver",
	// // }, service)

	// // log.Info("pod", req.Name, pod.Spec)

	return ctrl.Result{}, nil
}

func (r *ServiceReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&corev1.Service{}).
		Complete(r)
}
