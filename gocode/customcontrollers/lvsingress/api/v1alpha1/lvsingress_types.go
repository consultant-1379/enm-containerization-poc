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

package v1alpha1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	// corev1 "k8s.io/api/core/v1"
)

// EDIT THIS FILE!  THIS IS SCAFFOLDING FOR YOU TO OWN!
// NOTE: json tags are required.  Any new fields you add must have json tags for the fields to be serialized.

// LvsIngressSpec defines the desired state of LvsIngress
type LvsIngressSpec struct {
	// INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
	// Important: Run "make" to regenerate code after modifying this file
	VirtualServiceIP string  `json:"virtualServiceIP"`
	BackendService   Backend `json:"backendService"`
	// Event            Event   `json:"event,omitempty"`
}

// Backend services
type Backend struct {
	ServiceName      string         `json:"serviceName"`
	PortMappings     []PortMappings `json:"portMappings"`
	// ServiceEndPoints string         `json:"serviceEndpoints,omitempty"`
	// EndpointAddresses []corev1.EndpointAddress `json:"endpointAddresses,omitempty"`
	
}

// Event log on an endpoint
/*
Endpoint - the endpoint that  triggered the reconcile event
Action - The Action on the Endpoint
Reconciled - Set to true once handled at least once by Reconciler, 
*/
// type Event struct {
// 	// EndPoint string `json:"endpoint,omitempty"`
// 	EndpointAddresses []corev1.EndpointAddress `json:"endpointAddresses,omitempty"`
// 	Action   string `json:"action,omitempty"`
// 	Description string `json:"description,omitempty"`
// 	Reconciled bool `json:"reconciled,omitempty"`
// }

// PortMappings lb to service endpoint
type PortMappings struct {
	LbPort   int    `json:"lbPort"`
	SvcPort  int    `json:"svcPort"`
	Protocol string `json:"protocol"`
	Sch      string `json:"sch"`
}

// LvsIngressStatus defines the observed state of LvsIngress
type LvsIngressStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "make" to regenerate code after modifying this file
	// +optional
	// Total int `json:"total"`

	// // +optional
	// Active int `json:"active"`

	//+optional
	ChangeID int `json:"changeId,omitempty"`
}

// +kubebuilder:object:root=true

// LvsIngress is the Schema for the lvsingresses API
type LvsIngress struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   LvsIngressSpec   `json:"spec,omitempty"`
	Status LvsIngressStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// LvsIngressList contains a list of LvsIngress
type LvsIngressList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []LvsIngress `json:"items"`
}

func init() {
	SchemeBuilder.Register(&LvsIngress{}, &LvsIngressList{})
}
