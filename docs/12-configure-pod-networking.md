# Provisioning Pod Network

We chose to use CNI - [weave](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/) as our networking option.

### Install CNI plugins

Download the CNI Plugins required for weave on each of the worker nodes - `worker1` and `worker2`

`wget https://github.com/containernetworking/plugins/releases/download/v0.7.5/cni-plugins-amd64-v0.7.5.tgz`

Extract it to /opt/cni/bin directory

`sudo tar -xzvf cni-plugins-amd64-v0.7.5.tgz  --directory /opt/cni/bin/`

Reference: https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/#cni

### Deploy Weave Network

Deploy weave network. Run only once on the `master` node.

`somesh@k8s-ha-master1:~$ kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"`

Weave uses POD CIDR of `10.32.0.0/12` by default.

## Verification

List the registered Kubernetes nodes from the master node:

```
kubectl get nodes
kubectl get pods -n kube-system
kubectl get pods -n kube-system -o wide
kubectl logs weave-net-r2jsb weave -n kube-system
```

> output

```
somesh@k8s-ha-master1:~$ kubectl get nodes
NAME             STATUS   ROLES    AGE    VERSION
k8s-ha-worker1   Ready    <none>   141m   v1.13.0

somesh@k8s-ha-master1:~$ kubectl get pods -n kube-system
NAME              READY   STATUS    RESTARTS   AGE
weave-net-r2jsb   2/2     Running   1          5m14s

somesh@k8s-ha-master1:~$ kubectl get pods -n kube-system -o wide
NAME              READY   STATUS    RESTARTS   AGE     IP             NODE             NOMINATED NODE   READINESS GATES
weave-net-r2jsb   2/2     Running   1          9m20s   192.168.1.16   k8s-ha-worker1   <none>           <none>

somesh@k8s-ha-master1:~$ kubectl logs weave-net-r2jsb weave -n kube-system
Error from server (Forbidden): Forbidden (user=kube-apiserver, verb=get, resource=nodes, subresource=proxy) ( pods/log weave-net-r2jsb)
```

Reference: https://kubernetes.io/docs/tasks/administer-cluster/network-policy-provider/weave-network-policy/#install-the-weave-net-addon

Next: [Kube API Server to Kubelet Connectivity](13-kube-apiserver-to-kubelet.md)
