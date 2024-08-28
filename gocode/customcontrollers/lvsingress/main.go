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

package main

import (
	"flag"
	"os"

	//	"context"
	//	"fmt"

	routingv1alpha1 "gerrit.ericsson.se/oss/com.ericsson.oss.containerisation/enm-container-poc/gocode/customcontrollers/lvsingress/api/v1alpha1"
	"gerrit.ericsson.se/oss/com.ericsson.oss.containerisation/enm-container-poc/gocode/customcontrollers/lvsingress/controllers"
	"k8s.io/apimachinery/pkg/runtime"
	kscheme "k8s.io/client-go/kubernetes/scheme"
	_ "k8s.io/client-go/plugin/pkg/client/auth/gcp"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/log/zap"
	"sigs.k8s.io/controller-runtime/pkg/manager"

	// corev1 "k8s.io/api/core/v1"
	//"sigs.k8s.io/controller-runtime/pkg/client"
	apierrs "k8s.io/apimachinery/pkg/api/errors"
	// +kubebuilder:scaffold:imports
)

var (
	scheme   = runtime.NewScheme()
	setupLog = ctrl.Log.WithName("setup")
	k        controllers.Keepalived
)

func init() {

	routingv1alpha1.AddToScheme(scheme)
	kscheme.AddToScheme(scheme)
	// +kubebuilder:scaffold:scheme
}

func ignoreNotFound(err error) error {
	if apierrs.IsNotFound(err) {
		return nil
	}
	return err
}

func main() {
	var metricsAddr string
	flag.StringVar(&metricsAddr, "metrics-addr", ":8081", "The address the metric endpoint binds to.")

	flag.Parse()

	ctrl.SetLogger(zap.Logger(false))

	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{Scheme: scheme,
		MetricsBindAddress: metricsAddr,
		// LeaderElection:          true,
		// LeaderElectionID:        "lvs-controller",
		// LeaderElectionNamespace: "default"
	})
	if err != nil {
		setupLog.Error(err, "unable to start manager")
		os.Exit(1)
	}

	client := mgr.GetClient()
	configured := make(chan bool)
	mgr.Add(manager.RunnableFunc(func(<-chan struct{}) error {
		k.ConfigureKeepalived(client)
		configured <- true
		//	k.StartConntrackd()
		k.HandleSigterm()
		k.StartKeepalived()
		return nil
	}))

	mgr.Add(manager.RunnableFunc(func(<-chan struct{}) error {
		<-configured
		k.StartConntrackd()
		return nil
	}))

	// if err := k.ConfigureKeepalived(client); err != nil {
	// 	setupLog.Error(err, "unable to configure keepalived")
	// 	os.Exit(1)
	// }

	// setupLog.Info("configured keepalived")
	// k.Start()
	setupLog.Info("keepalived and keepalived process started")
	//	go k.HandleSigterm(k)

	err = (&controllers.SvcReconciler{
		Client: client,
		Log:    ctrl.Log.WithName("controllers").WithName("Services"),
	}).SetupWithManager(mgr)
	if err != nil {
		setupLog.Error(err, "unable to create controller", "controller", "Services")
		os.Exit(1)
	}

	err = (&controllers.LvsIngressReconciler{
		Client: client,
		//	Keepalived: k,
		Log: ctrl.Log.WithName("controllers").WithName("LvsIngress"),
	}).SetupWithManager(mgr)
	if err != nil {
		setupLog.Error(err, "unable to create controller", "controller", "LvsIngress")
		os.Exit(1)
	}

	err = (&controllers.EndpointReconciler{
		Client: client,
		Log:    ctrl.Log.WithName("controllers").WithName("Endpoints"),
	}).SetupWithManager(mgr)
	if err != nil {
		setupLog.Error(err, "unable to create controller", "controller", "Endpoints")
		os.Exit(1)
	}

	// +kubebuilder:scaffold:builder

	setupLog.Info("starting manager")
	if err := mgr.Start(ctrl.SetupSignalHandler()); err != nil {
		setupLog.Error(err, "problem running manager")
		os.Exit(1)
	}

	setupLog.Info("voila........")
}
