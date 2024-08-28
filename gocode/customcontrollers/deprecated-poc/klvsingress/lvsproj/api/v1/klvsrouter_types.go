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

package v1

import (
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// EDIT THIS FILE!  THIS IS SCAFFOLDING FOR YOU TO OWN!
// NOTE: json tags are required.  Any new fields you add must have json tags for the fields to be serialized.

// KlvsRouterSpec defines the desired state of KlvsRouter
type KlvsRouterSpec struct {
	// INSERT ADDITIONAL SPEC FIELDS - desired state of cluster
	// Important: Run "make" to regenerate code after modifying this file

	Vip     string  `json:"vip,omitempty"`
	Service Service `json:"service,omitempty"`
}

type Service struct {
	Name            string           `json:"name,omitempty"`
	ServiceMappings []ServiceMapping `json:"serviceMappings,omitempty"`
	Endpoints       []string         `json:"serviceEndpoints,omitempty"`
}

type ServiceMapping struct {
	VipPort   int    `json:"vipPort,omitempty"`
	PortName  string `json:"portName,omitempty"`
	Protocol  string `json:"protocol,omitempty"`
	Scheduler string `json:"scheduler,omitempty"`
}

// KlvsRouterStatus defines the observed state of KlvsRouter
type KlvsRouterStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "make" to regenerate code after modifying this file
	Active int `json:"active,omitempty"`
	Total  int `json:"total,omitempty"`
}

// +kubebuilder:object:root=true

// KlvsRouter is the Schema for the klvsrouters API
type KlvsRouter struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   KlvsRouterSpec   `json:"spec,omitempty"`
	Status KlvsRouterStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// KlvsRouterList contains a list of KlvsRouter
type KlvsRouterList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []KlvsRouter `json:"	"`
}

func init() {
	SchemeBuilder.Register(&KlvsRouter{}, &KlvsRouterList{})
}
