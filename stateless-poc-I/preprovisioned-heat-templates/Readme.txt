- templates with v2 have been updated to include ENM POC Workarounds
- Updates cover below from confluence pages.
    - Adds the ENM loadbalancer and iptables rules
    - Adds static route to Ansible machine
        https://confluence-nam.lmera.ericsson.se/display/EOVP/Hybrid+Deployment+Networking
- Updates resolv.conf with service registry information
    https://confluence-nam.lmera.ericsson.se/display/EOVP/NFS+Mounts
- Add docker ip and ca.crt
    https://confluence-nam.lmera.ericsson.se/display/EOVP/Local+Docker+Registry
-	Added master and nodes alias to host file on ansible server.

To Install update v2_env_cloud4b.yaml with POD site specific data
# openstack stack create -e v2_env_cloud4b.yaml -t v2-erikube-main.yaml k8s