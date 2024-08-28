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
//  if apierrs.IsNotFound(err) {
//      return nil
//  }
//  return err
// }

// Reconcile EndPoints
// +kubebuilder:rbac:groups=routers.lvsrouter.ericsson.com,resources=klvsrouters,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=routers.lvsrouter.ericsson.com,resources=klvsrouters/status,verbs=get;update;patch
// +kubebuilder:rbac:groups=,resources=services,verbs=get;list;watch;create;update;patch;delete
// +kubebuilder:rbac:groups=,resources=endpoints,verbs=get;list;watch;create;update;patch;delete
func (r *ServiceReconciler) Reconcile(req ctrl.Request) (ctrl.Result, error) {
	_ = context.Background()
	_ = r.Log.WithValues("service-reconciler", req.NamespacedName)

	// OUR LOGIC HERE

	return ctrl.Result{}, nil
}

// SetupWithManager in main.go
func (r *ServiceReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&corev1.Endpoints{}).
		Complete(r)
}
