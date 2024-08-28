### EXPLANATION OF HOW NGINX CONTROLLER WORKS AND SIMPLE GETTING STARTED GUIDE ###
### The charts have been modified from open source version to achieve ENM automatic configuartion ###


###############################################
GETTING STARTED WITH ENM NGINX CONTROLLER
###############################################
1. Create any SVC (Kubernetes svc object) that nginx-controller will be proxying first, otherwise nginx will fail to start. This is beacause nginx expects the SVC to be resolvable. The backend endpoints/pods handling service does not have to exist

----
e.g.
apiVersion: v1
kind: Service
metadata:
  name: tcpserver
  #namespace: heptio-contour
spec:
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: https
      port: 443
      targetPort: 443
    - name: sometcp
      port: 8080
      targetPort: 8080
    - name: someothertcp
      port: 7070
      targetPort: 7070
  selector:
    app: tcpserver

----

2. Modify values.yaml with the created services

----
#cport = controller listening port, this must match the port the client will be sending traffic to

e.g.
tcp:
  mscm:
    lb: "hash $remote_addr"
    cport: 5900
    service: "tea-svc:80"
  tcps:
    lb : "hash $remote_addr"
    cport: 5000
    service: "tcpserver:8080"
  servicea:
    lb : "least_conn"
    cport: 9000
    service: "service-a:80"
"values.yaml" 191L, 10950C                                                                                                                      191,5         Bot

----

# in the same directory as "Chart.yaml"
3. install --name abdul-controller .

This will result in
a) Controller pod created listening on "cports" defined above
b) A LoadBalancer Service created listening on the same "cports"

   -- on current ECCD/ECFE this will result in an external address logically wired to the LoadBalancer Service Object - (in reality wired to node as next hop). This functionality is implemented by ECFE/MetalLB

---
e.g.
[eccd@director-1-pf-eccd-17 nginx-ingress]$ kubectl get svc | grep Load
nginx-ingress                   LoadBalancer   10.96.49.159    10.32.184.150   80:30421/TCP,443:30368/TCP,5900:31543/TCP,9000:32431/TCP,5000:32301/TCP   22h

---

   -- on AWS this will result in Loadbalancer VMs spinning upp with the external IP address wired here and these will fwd traffic to the LoadBalancer SVC Object


c) This will create a configmap that corresponds with the actual nginx config snippet used by the nginx controller to route traffic. This gets inserted in the actual nginx pod config.

---
[eccd@director-1-pf-eccd-17 nginx-ingress]$ kubectl describe cm nginx-config 
e.g.

Name:         nginx-config
Namespace:    default
Labels:       app.kubernetes.io/instance=test-2
              app.kubernetes.io/managed-by=Tiller
              app.kubernetes.io/name=nginx-ingress
              helm.sh/chart=nginx-ingress-0.3.5
Annotations:  <none>

Data
====
stream-snippets:
----
upstream mscm-tcp {
   hash $remote_addr;
   server tea-svc:80;
}

server {
   listen 5900;
   proxy_pass mscm-tcp;
}
upstream servicea-tcp {
   least_conn;
   server service-a:80;
}

server {
   listen 9000;
   proxy_pass servicea-tcp;
}
upstream tcps-tcp {
   hash $remote_addr;
   server tcpserver:8080;
}

server {
   listen 5000;
   proxy_pass tcps-tcp;
}

Events:  <none>

---




###### BELOW IS ORIGINAL README. LEAVING FOR REFERENCE. AS SPECIFIED ABOVE, CHARTS HAVE BEEN MODIFIED FROM ORIGINAL ##########




# NGINX Ingress Controller Helm Chart

## Introduction

This chart deploys the NGINX Ingress controller in your Kubernetes cluster.

## Prerequisites

  - Kubernetes 1.6+.
  - Helm 2.8.x+.
  - Git.
  - If you’d like to use NGINX Plus:
    - Build an Ingress controller image with NGINX Plus and push it to your private registry by following the instructions from [here](../../build/README.md).
    - Update the `controller.image.repository` field of the `values-plus.yaml` accordingly.

## Installing the Chart

1. Clone the Ingress controller repo:
    ```console
    $ git clone https://github.com/nginxinc/kubernetes-ingress/
    ```
2. Change your working directory to /deployments/helm-chart:
    ```console
    $ cd kubernetes-ingress/deployments/helm-chart
    ```
3. To install the chart with the release name my-release (my-release is the name that you choose):

    For NGINX:
    ```console
    $ helm install --name my-release .
    ```

    For NGINX Plus:
    ```console
    $ helm install --name my-release -f values-plus.yaml .
    ```

    The command deploys the Ingress controller in your Kubernetes cluster in the default configuration. The configuration section lists the parameters that can be configured during installation.

    When deploying the Ingress controller, make sure to use your own TLS certificate and key for the default server rather than the default pre-generated ones. Read the [Configuration](#Configuration) section below to see how to configure a TLS certificate and key for the default server. Note that the default server returns the Not Found page with the 404 status code for all requests for domains for which there are no Ingress rules defined.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the release `my-release`

```console
$ helm delete my-release
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following tables lists the configurable parameters of the NGINX Ingress controller chart and their default values.

Parameter | Description | Default
--- | --- | ---
`controller.name` | The name of the Ingress controller daemonset or deployment. | nginx-ingress
`controller.kind` | The kind of the Ingress controller installation - deployment or daemonset. | deployment
`controller.nginxplus` | Deploys the Ingress controller for NGINX Plus. | false
`controller.hostNetwork` | Enables the Ingress controller pods to use the host's network namespace. | false
`controller.nginxDebug` | Enables debugging for NGINX. Uses the `nginx-debug` binary. Requires `error-log-level: debug` in the ConfigMap via `controller.config.entries`. | false
`controller.image.repository` | The image repository of the Ingress controller. | nginx/nginx-ingress
`controller.image.tag` | The tag of the Ingress controller image. | edge
`controller.image.pullPolicy` | The pull policy for the Ingress controller image. | IfNotPresent
`controller.config.entries` | The entries of the ConfigMap for customizing NGINX configuration. | {}
`controller.defaultTLS.cert` | The base64-encoded TLS certificate for the default HTTPS server. If not specified, a pre-generated self-signed certificate is used. **Note:** It is recommended that you specify your own certificate. | A pre-generated self-signed certificate.
`controller.defaultTLS.key` | The base64-encoded TLS key for the default HTTPS server. **Note:** If not specified, a pre-generated key is used. It is recommended that you specify your own key. | A pre-generated key.
`controller.defaultTLS.secret` | The secret with a TLS certificate and key for the default HTTPS server. The value must follow the following format: `<namespace>/<name>`. Used as an alternative to specifiying a certifcate and key using `controller.defaultTLS.cert` and `controller.defaultTLS.key` parameters. | None
`controller.wildcardTLS.cert` | The base64-encoded TLS certificate for every Ingress host that has TLS enabled but no secret specified. If the parameter is not set, for such Ingress hosts NGINX will break any attempt to establish a TLS connection. | None
`controller.wildcardTLS.key` | The base64-encoded TLS key for every Ingress host that has TLS enabled but no secret specified. If the parameter is not set, for such Ingress hosts NGINX will break any attempt to establish a TLS connection. | None
`controller.wildcardTLS.secret` | The secret with a TLS certificate and key for every Ingress host that has TLS enabled but no secret specified. The value must follow the following format: `<namespace>/<name>`. Used as an alternative to specifying a certificate and key using `controller.wildcardTLS.cert` and `controller.wildcardTLS.key` parameters. | None
`controller.nodeSelector` | The node selector for pod assignment for the Ingress controller pods. | {}
`controller.terminationGracePeriodSeconds` | The termination grace period of the Ingress controller pod. | 30
`controller.tolerations` | The tolerations of the Ingress controller pods. | []
`controller.affinity` | The affinity of the Ingress controller pods. | {}
`controller.replicaCount` | The number of replicas of the Ingress controller deployment. | 1
`controller.ingressClass` | A class of the Ingress controller. The Ingress controller only processes Ingress resources that belong to its class - i.e. have the annotation `"kubernetes.io/ingress.class"` equal to the class. Additionally, the Ingress controller processes Ingress resources that do not have that annotation which can be disabled by setting the "-use-ingress-class-only" flag. | nginx
`controller.useIngressClassOnly` | Ignore Ingress resources without the `"kubernetes.io/ingress.class"` annotation. | false
`controller.watchNamespace` | Namespace to watch for Ingress resources. By default the Ingress controller watches all namespaces. | ""
`controller.healthStatus` | Add a location "/nginx-health" to the default server. The location responds with the 200 status code for any request. Useful for external health-checking of the Ingress controller. | false
`controller.nginxStatus.enable` | Enable the NGINX stub_status, or the NGINX Plus API. | true
`controller.nginxStatus.port` | Set the port where the NGINX stub_status or the NGINX Plus API is exposed. | 8080
`controller.nginxStatus.allowCidrs` | Whitelist IPv4 IP/CIDR blocks to allow access to NGINX stub_status or the NGINX Plus API. Separate multiple IP/CIDR by commas. | 127.0.0.1
`controller.service.create` | Creates a service to expose the Ingress controller pods. | true
`controller.service.type` | The type of service to create for the Ingress controller. | LoadBalancer
`controller.service.externalTrafficPolicy` | The externalTrafficPolicy of the service. The value Local preserves the client source IP. | Local
`controller.service.annotations` | The annotations of the Ingress controller service. | {}
`controller.service.loadBalancerIP` | The static IP address for the load balancer. Requires `controller.service.type` set to `LoadBalancer`. The cloud provider must support this feature. | ""
`controller.service.externalIPs` | The list of external IPs for the Ingress controller service. | []
`controller.service.loadBalancerSourceRanges` | The IP ranges (CIDR) that are allowed to access the load balancer. Requires `controller.service.type` set to `LoadBalancer`. The cloud provider must support this feature. | []
`controller.service.httpPort.enable` | Enables the HTTP port for the Ingress controller service. | true
`controller.service.httpPort.port` | The HTTP port of the Ingress controller service. | 80
`controller.service.httpPort.nodePort` | The custom NodePort for the HTTP port. Requires `controller.service.type` set to `NodePort`. | ""
`controller.service.httpsPort.enable` | Enables the HTTPS port for the Ingress controller service. | true
`controller.service.httpsPort.port` | The HTTPS port of the Ingress controller service. | 443
`controller.service.httpsPort.nodePort` | The custom NodePort for the HTTPS port. Requires `controller.service.type` set to `NodePort`.  | ""
`controller.serviceAccount.name` | The name of the service account of the Ingress controller pods. Used for RBAC. | nginx-ingress
`controller.serviceAccount.imagePullSecrets` | The names of the secrets containing docker registry credentials. | []
`controller.reportIngressStatus.enable` | Update the address field in the status of Ingresses resources with an external address of the Ingress controller. You must also specify the source of the external address either through an external service via `controller.reportIngressStatus.externalService` or the `external-status-address` entry in the ConfigMap via `controller.config.entries`. **Note:** `controller.config.entries.external-status-address` takes precedence if both are set. | true
`controller.reportIngressStatus.externalService` | Specifies the name of the service with the type LoadBalancer through which the Ingress controller is exposed externally. The external address of the service is used when reporting the status of Ingress resources. `controller.reportIngressStatus.enable` must be set to `true`. | nginx-ingress
`controller.reportIngressStatus.enableLeaderElection` | Enable Leader election to avoid multiple replicas of the controller reporting the status of Ingress resources. `controller.reportIngressStatus.enable` must be set to `true`. | true
`rbac.create` | Configures RBAC. | true
`prometheus.create` | Expose NGINX or NGINX Plus metrics in the Prometheus format. | false
`prometheus.port` | Configures the port to scrape the metrics. | 9113


Example:
```console
$ cd kubernetes-ingress/helm-chart
$ helm install --name my-release . --set controller.replicaCount=5
```

## Notes
* The values-icp.yaml file is used for deploying the Ingress controller on IBM Cloud Private. See the [blog post](https://www.nginx.com/blog/nginx-ingress-controller-ibm-cloud-private/) for more details.
