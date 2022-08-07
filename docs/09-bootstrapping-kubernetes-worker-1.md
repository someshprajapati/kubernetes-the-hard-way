# Bootstrapping the Kubernetes Worker Nodes

In this lab you will bootstrap 2 Kubernetes worker nodes. We already have [Docker](https://www.docker.com) installed on these nodes.

We will now install the kubernetes components
- [kubelet](https://kubernetes.io/docs/admin/kubelet)
- [kube-proxy](https://kubernetes.io/docs/concepts/cluster-administration/proxies).

## Prerequisites

The Certificates and Configuration are created on `master1` node and then copied over to workers using `scp`. 
Once this is done, the commands are to be run on first worker instance: `worker1`. Login to first worker instance using SSH Terminal.

### Provisioning Kubelet Client Certificates

Kubernetes uses a [special-purpose authorization mode](https://kubernetes.io/docs/admin/authorization/node/) called Node Authorizer, that specifically authorizes API requests made by [Kubelets](https://kubernetes.io/docs/concepts/overview/components/#kubelet). In order to be authorized by the Node Authorizer, Kubelets must use a credential that identifies them as being in the `system:nodes` group, with a username of `system:node:<nodeName>`. In this section you will create a certificate for each Kubernetes worker node that meets the Node Authorizer requirements.

Generate a certificate and private key for one worker node:

> On master1:

```
cat > openssl-k8s-ha-worker1.cnf <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = k8s-ha-worker1
IP.1 = 192.168.1.16
EOF

openssl genrsa -out k8s-ha-worker1.key 2048
openssl req -new -key k8s-ha-worker1.key -subj "/CN=system:node:k8s-ha-worker1/O=system:nodes" -out k8s-ha-worker1.csr -config openssl-k8s-ha-worker1.cnf
openssl x509 -req -in k8s-ha-worker1.csr -CA ca.crt -CAkey ca.key -CAcreateserial  -out k8s-ha-worker1.crt -extensions v3_req -extfile openssl-k8s-ha-worker1.cnf -days 1000
```

> Results:

```
k8s-ha-worker1.key
k8s-ha-worker1.crt
```

### The kubelet Kubernetes Configuration File

When generating kubeconfig files for Kubelets the client certificate matching the Kubelet's node name must be used. This will ensure Kubelets are properly authorized by the Kubernetes [Node Authorizer](https://kubernetes.io/docs/admin/authorization/node/).

Get the kub-api server load-balancer IP.
```
LOADBALANCER_ADDRESS=192.168.1.18
```

Generate a kubeconfig file for the first worker node.

> On master1:
```
{
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=ca.crt \
    --embed-certs=true \
    --server=https://${LOADBALANCER_ADDRESS}:6443 \
    --kubeconfig=k8s-ha-worker1.kubeconfig

  kubectl config set-credentials system:node:k8s-ha-worker1 \
    --client-certificate=k8s-ha-worker1.crt \
    --client-key=k8s-ha-worker1.key \
    --embed-certs=true \
    --kubeconfig=k8s-ha-worker1.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:k8s-ha-worker1 \
    --kubeconfig=k8s-ha-worker1.kubeconfig

  kubectl config use-context default --kubeconfig=k8s-ha-worker1.kubeconfig
}
```

> Results:

```
k8s-ha-worker1.kubeconfig
```

### Copy certificates, private keys and kubeconfig files to the worker node:
> On master1:
```
somesh@k8s-ha-master1:~$ scp ca.crt k8s-ha-worker1.crt k8s-ha-worker1.key k8s-ha-worker1.kubeconfig k8s-ha-worker1:~/
```

### Download and Install Worker Binaries

Going forward all activities are to be done on the `worker1` node.

> On worker1:
```
somesh@k8s-ha-worker1:~$ wget -q --show-progress --https-only --timestamping \
  https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-proxy \
  https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kubelet
```

Reference: https://kubernetes.io/docs/setup/release/#node-binaries

Create the installation directories:

```
somesh@k8s-ha-worker1:~$ sudo mkdir -p \
  /etc/cni/net.d \
  /opt/cni/bin \
  /var/lib/kubelet \
  /var/lib/kube-proxy \
  /var/lib/kubernetes \
  /var/run/kubernetes
```

Install the worker binaries:

```
{
  chmod +x kubectl kube-proxy kubelet
  sudo mv kubectl kube-proxy kubelet /usr/local/bin/
}
```

### Configure the Kubelet
> On worker1:
```
{
  sudo mv ${HOSTNAME}.key ${HOSTNAME}.crt /var/lib/kubelet/
  sudo mv ${HOSTNAME}.kubeconfig /var/lib/kubelet/kubeconfig
  sudo mv ca.crt /var/lib/kubernetes/
}
```

Create the `kubelet-config.yaml` configuration file:

```
somesh@k8s-ha-worker1:~$ cat <<EOF | sudo tee /var/lib/kubelet/kubelet-config.yaml
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "/var/lib/kubernetes/ca.crt"
authorization:
  mode: Webhook
clusterDomain: "cluster.local"
clusterDNS:
  - "10.96.0.10"
resolvConf: "/run/systemd/resolve/resolv.conf"
runtimeRequestTimeout: "15m"
EOF
```

> The `resolvConf` configuration is used to avoid loops when using CoreDNS for service discovery on systems running `systemd-resolved`.

Create the `kubelet.service` systemd unit file:

```
somesh@k8s-ha-worker1:~$ cat <<EOF | sudo tee /etc/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/kubelet \\
  --config=/var/lib/kubelet/kubelet-config.yaml \\
  --image-pull-progress-deadline=2m \\
  --kubeconfig=/var/lib/kubelet/kubeconfig \\
  --tls-cert-file=/var/lib/kubelet/${HOSTNAME}.crt \\
  --tls-private-key-file=/var/lib/kubelet/${HOSTNAME}.key \\
  --network-plugin=cni \\
  --register-node=true \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubernetes Proxy
> On worker1:
```
somesh@k8s-ha-worker1:~$ sudo mv kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
```

Create the `kube-proxy-config.yaml` configuration file:

```
somesh@k8s-ha-worker1:~$ cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "192.168.1.0/24"
EOF
```

Create the `kube-proxy.service` systemd unit file:

```
somesh@k8s-ha-worker1:~$ cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Start the Worker Services
> On worker1:
```
{
  sudo systemctl daemon-reload
  sudo systemctl enable kubelet kube-proxy
  sudo systemctl start kubelet kube-proxy
}
```

> Remember to run the above commands on worker node: `worker1`

## Verification
> On master1:

List the registered Kubernetes nodes from the master node:

```
somesh@k8s-ha-master1:~$ kubectl get nodes --kubeconfig admin.kubeconfig

somesh@k8s-ha-master1:~$ kubectl get nodes
```

> output

```
NAME             STATUS     ROLES    AGE     VERSION
k8s-ha-worker1   NotReady   <none>   3m50s   v1.13.0
```

> Note: It is OK for the worker node to be in a NotReady state.
  That is because we haven't configured Networking yet.

Optional: At this point you may run the certificate verification script to make sure all certificates are configured correctly. Follow the instructions [here](verify-certificates.md)

Next: [Bootstrapping the Kubernetes Worker2 Nodes](09-bootstrapping-kubernetes-worker-2.md)
