cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg 
frontend kubernetes
    bind 192.168.1.18:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server k8s-ha-master1 192.168.1.14:6443 check fall 3 rise 2
    server k8s-ha-master2 192.168.1.15:6443 check fall 3 rise 2
EOF