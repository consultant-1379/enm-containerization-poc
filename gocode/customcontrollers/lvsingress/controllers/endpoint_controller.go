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
	"fmt"
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
	routingv1alpha1 "gerrit.ericsson.se/oss/com.ericsson.oss.containerisation/enm-container-poc/gocode/customcontrollers/lvsingress/api/v1alpha1"
	// routersv1 "com.ericsson.oss.microservices/lvsrouter/api/v1"
	// "time"
	// "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)



// EndpointReconciler reconciles a Kubernetes object
type EndpointReconciler struct {
	client.Client
	Log    logr.Logger
	Scheme *runtime.Scheme
}



//TODO REMOVING FROM MAIN.GO FOR NOW

// Reconcile CRD object
// +kubebuilder:rbac:groups=routing.lvsingress.ericsson.com,resources=lvsingresses,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=routing.lvsingress.ericsson.com,resources=lvsingresses/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=,resources=services,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=,resources=pods,verbs=get;list;watch;create;update;patch;delete
func (r *EndpointReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	// _ = context.Background()
	// _ = r.Log.WithValues("endpointreconciler", req.NamespacedName)

	ctx := context.Background()
	log := r.Log.WithValues("endpointreconciler", req.NamespacedName)

	var endpoint corev1.Endpoints

	if err := r.Get(ctx, req.NamespacedName, &endpoint); err != nil {
		log.Error(err, "unable to fetch endpoint, ignore not found")
		// we'll ignore not-found errors, since they can't be fixed by an immediate
		// requeue (we'll need to wait for a new notification), and we can get them
		// on deleted requests.
		return ctrl.Result{}, ignoreNotFound(err)
	}

	labels := endpoint.ObjectMeta.Labels
	//1. CHECK FOR LABEL TO SEE IF WE'RE INTERESTED IN THIS CRD
	if val, ok := labels[lvsIngressLabelKey]; ok {
		log.Info("endpoint contains label, retrievng CRD", req.Name,val)
		//2. GET ASSOC CRD
		ingressCrd,err := r.GetCrd(req,ctx,val)

		if err != nil{

			log.Error(err, "unable to fetch CRD endpoints for ")
			return ctrl.Result{}, ignoreNotFound(err)
		}
		fmt.Println(ingressCrd)
		fmt.Println(err)

		//3. GET ADDRESSES, AND UPDATE EVENT
		// epSubsets :=  endpoint.Subsets

		// //currently assuming an array of size 1
		// for _, ep := range epSubsets {
		// 	// addresses := ep.Addresses
		// 	addresses := ep.Addresses
		// 	ingressCrd.Spec.Event.EndpointAddresses = addresses
		// 	ingressCrd.Spec.Event.Description  = endpointModification
		// }
		// ingressCrd.Spec.Event.Action = modified
		// ingressCrd.Spec.Event.Description = endpointModification
		changeID := ingressCrd.Status.ChangeID
		changeID++
		ingressCrd.Status.ChangeID=changeID
		log.Info("Updating CRD EVent to trigger Reconcilitations", req.Name,changeID)
		//4. NOW UPDATE THE OBJ. LVSINGRESS RECONCILER WILL RECONCILE ANY DIFFERENCES WITH CRD.
		if err := r.Update(context.TODO(), &ingressCrd); err != nil{
		//   if err := r.Update(context.TODO(),  client.ObjectKey{ "Name": "lvsingress-sample"},&ingressCrd); err != nil{
			// (ctx, client.ObjectKey{Namespace: req.Namespace, Name: serviceLabel}, &ingressCrd)

			log.Error(err, "Error updating Event on CRD")
			return ctrl.Result{}, ignoreNotFound(err)
		}

	}


	return ctrl.Result{}, nil
}



//GetCrd the CRD associated with the modified Endpoints object
func (r *EndpointReconciler) GetCrd(req ctrl.Request, ctx context.Context, serviceLabel string,) (routingv1alpha1.LvsIngress, error) {

	// var ingressCrd routingv1alpha1.LvsIngress
	 ingressCrd := routingv1alpha1.LvsIngress{}
	
		if err := r.Get(ctx, client.ObjectKey{Namespace: req.Namespace, Name: serviceLabel}, &ingressCrd); err != nil {
		r.Log.Error(err, "unable to fetch LvsIngress endpoints ")

		return ingressCrd,err
	}
	

	return ingressCrd,nil

}

//SetupWithManager Set up reconciler with the manager
func (r *EndpointReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&corev1.Endpoints{}).
		Complete(r)
}
