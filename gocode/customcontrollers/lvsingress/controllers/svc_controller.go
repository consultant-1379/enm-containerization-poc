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
	routingv1alpha1 "gerrit.ericsson.se/oss/com.ericsson.oss.containerisation/enm-container-poc/gocode/customcontrollers/lvsingress/api/v1alpha1"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"
	// routersv1 "com.ericsson.oss.microservices/lvsrouter/api/v1"
	// "time"
	// "k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
)

// SvcReconciler reconciles a Kubernetes object
type SvcReconciler struct {
	client.Client
	Log    logr.Logger
	Scheme *runtime.Scheme
}

// Reconcile CRD object
// +kubebuilder:rbac:groups=routing.lvsingress.ericsson.com,resources=lvsingresses,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=routing.lvsingress.ericsson.com,resources=lvsingresses/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=,resources=services,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=,resources=pods,verbs=get;list;watch;create;update;patch;delete
func (r *SvcReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {

	ctx := context.Background()
	log := r.Log.WithValues("SvcReconciler", req.NamespacedName)

	var service corev1.Service

	//in the case where a svc cannot be found and a CRD exists then we mark the CRD for recnciliation
	if err := r.Get(ctx, req.NamespacedName, &service); err != nil {
		log.Error(err, "unable to fetch svc")

		ingressCrd, error := r.GetCrdForReconciliation(ctx, req)
		result,error := r.MarkCrdForReconciliation(&ingressCrd)
		fmt.Println("MArked CRD for reconciliation: ",result)

		fmt.Println(ingressCrd)
		fmt.Println(error)
		// ignoreNotFound applies to the SVC message
		return ctrl.Result{}, ignoreNotFound(err)
	}


	return ctrl.Result{}, nil
}

//MarkCrdForReconciliation retrieve the CRD and mark for reconciliation
func (r *SvcReconciler) GetCrdForReconciliation(ctx context.Context, req ctrl.Request) (routingv1alpha1.LvsIngress, error) {
	//get endpoints list -- all endpoints
	//  eplist := &corev1.EndpointsList{}

	ingressCrds := routingv1alpha1.LvsIngressList{}
	ingressCrd := routingv1alpha1.LvsIngress{}
	serviceName := req.NamespacedName.Name

	if err := r.List(ctx, &ingressCrds); err != nil {
		r.Log.Error(err, "unable to fetch crd list")
		return ingressCrd, err
	}

	for _, crd := range ingressCrds.Items {

		if serviceName == crd.Spec.BackendService.ServiceName {
			r.Log.Info("MAtching CRD found... ", crd.Spec.BackendService.ServiceName, serviceName)
			ingressCrd = crd
			break

		}

	}
	return ingressCrd, nil

}

//MarkCrdForReconciliation update CRD for reconciliation by LvsINgressReconciler
func (r *SvcReconciler) MarkCrdForReconciliation(ingressCrd *routingv1alpha1.LvsIngress) (bool, error){
	
	// ingressCrd.Spec.Event.Reconciled=false;
	// ingressCrd.Status.RequiresReconciliation=true
	// var endpointAddresses []corev1.EndpointAddress
	// ingressCrd.Spec.Event.EndpointAddresses=endpointAddresses
	changeID := ingressCrd.Status.ChangeID
	changeID++
	ingressCrd.Status.ChangeID=changeID
	// r.Log.Info("Updating CRD EVent to trigger Reconcilitations", req.Name,changeID)

	if err := r.Update(context.TODO(), ingressCrd); err != nil{

		r.Log.Error(err, "Error updating ingressCrd.Spec.BackendService.ServiceEndPoints on initial reconcile on LvsIngress")
		return false, ignoreNotFound(err)
	}

	return true,nil
}

//SetupWithManager Set up reconciler with the manager
func (r *SvcReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&corev1.Service{}).
		Complete(r)
}
