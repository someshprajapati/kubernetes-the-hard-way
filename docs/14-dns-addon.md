# Deploying the DNS Cluster Add-on

In this lab you will deploy the [DNS add-on](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) which provides DNS based service discovery, backed by [CoreDNS](https://coredns.io/), to applications running inside the Kubernetes cluster.

## The DNS Cluster Add-on

Deploy the `coredns` cluster add-on:

```
somesh@k8s-ha-master1:~$ kubectl apply -f https://raw.githubusercontent.com/mmumshad/kubernetes-the-hard-way/master/deployments/coredns.yaml
```

> output

```
serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.extensions/coredns created
service/kube-dns created
```

List the pods created by the `kube-dns` deployment:

```
somesh@k8s-ha-master1:~$ kubectl get pods -l k8s-app=kube-dns -n kube-system
```

> output

```
NAME                       READY   STATUS    RESTARTS   AGE
coredns-69cbb76ff8-mrq7h   1/1     Running   0          3m10s
coredns-69cbb76ff8-rtzml   1/1     Running   0          3m10s
```

Reference: https://kubernetes.io/docs/tasks/administer-cluster/coredns/#installing-coredns

## Verification

Create a `busybox` deployment:

```
somesh@k8s-ha-master1:~$ kubectl run --generator=run-pod/v1  busybox --image=busybox:1.28 --command -- sleep 3600
```

List the pod created by the `busybox` deployment:

```
somesh@k8s-ha-master1:~$ kubectl get pods -l run=busybox
```

> output

```
NAME      READY   STATUS    RESTARTS   AGE
busybox   1/1     Running   0          48s
```

Execute a DNS lookup for the `kubernetes` service inside the `busybox` pod:

```
somesh@k8s-ha-master1:~$ kubectl exec -ti busybox -- nslookup kubernetes
```

> output

```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
```

Next: [Smoke Test](15-smoke-test.md)
