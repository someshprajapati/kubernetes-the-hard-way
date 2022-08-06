# Provisioning Compute Resources

Note: You must have VMware Fusion configured at this point.

We are going to deploy the below set of servers on VMware Fusion. Using the below OS for the setup.

```
NAME="Ubuntu"
VERSION="20.04.4 LTS (Focal Fossa)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 20.04.4 LTS"
VERSION_ID="20.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=focal
UBUNTU_CODENAME=focal
```

- Deploy 5 VMs --> 2 Master, 2 Worker and 1 Loadbalancer with the name 'k8s-ha-*'

- Set's IP addresses in the range 192.168.1

    |      VM      |     VM Name     |     Purpose   |     IP       |  Forwarded Port  |
    | ------------ | --------------- | ------------- | ------------ | ---------------- |
    | master1      | k8s-ha-master1  | Master        | 192.168.1.14 |     2711         |
    | master2      | k8s-ha-master2  | Master        | 192.168.1.15 |     2712         |
    | worker1      | k8s-ha-worker1  | Worker        | 192.168.1.16 |     2721         |
    | worker2      | k8s-ha-worker2  | Worker        | 192.168.1.17 |     2722         |
    | loadbalancer | k8s-ha-lb       | LoadBalancer  | 192.168.1.18 |     2730         |


- Add's a DNS entry to each of the nodes to access internet
    > DNS: 8.8.8.8

- Install's Docker on Worker nodes
- Runs the below command on all nodes to allow for network forwarding in IP Tables.
  This is required for kubernetes networking to function correctly.
    > sysctl net.bridge.bridge-nf-call-iptables=1


## SSH Using SSH Client Tools

I am using my favourite SSH Terminal tool (iTerm).

**Private Key Path:** `~/.ssh/id_rsa`

**Username:** `someshp`

## Verify Environment

- Ensure all VMs are up
- Ensure VMs are assigned the above IP addresses

> master1
```
somesh@k8s-ha-master1:~$ hostname
k8s-ha-master1

somesh@k8s-ha-master1:~$ ifconfig | grep -w inet
        inet 192.168.1.14  netmask 255.255.255.0  broadcast 192.168.1.255
        inet 127.0.0.1  netmask 255.0.0.0
```

> master2
```
somesh@k8s-ha-master2:~$ hostname
k8s-ha-master2

somesh@k8s-ha-master2:~$ ifconfig | grep -w inet
        inet 192.168.1.15  netmask 255.255.255.0  broadcast 192.168.1.255
        inet 127.0.0.1  netmask 255.0.0.0
```

> worker1
```
somesh@k8s-ha-worker1:~$ hostname
k8s-ha-worker1

somesh@k8s-ha-worker1:~$ ifconfig | grep -w inet
        inet 192.168.1.16  netmask 255.255.255.0  broadcast 192.168.1.255
        inet 127.0.0.1  netmask 255.0.0.0
```

> worker2
```
somesh@k8s-ha-worker2:~$ hostname
k8s-ha-worker2

somesh@k8s-ha-worker2:~$ ifconfig | grep -w inet
        inet 192.168.1.17  netmask 255.255.255.0  broadcast 192.168.1.255
        inet 127.0.0.1  netmask 255.0.0.0
```

> loadbalancer
```
somesh@k8s-ha-lb:~$ hostname
k8s-ha-lb

somesh@k8s-ha-lb:~$ ifconfig | grep -w inet
        inet 192.168.1.18  netmask 255.255.255.0  broadcast 192.168.1.255
        inet 127.0.0.1  netmask 255.0.0.0
```

- Ensure you can SSH into these VMs using the IP and private keys
- Ensure the VMs can ping each other
- Ensure the worker nodes have Docker installed on them [Install Docker](https://docs.docker.com/engine/install/ubuntu/). Version: 20.10
  > command `sudo docker version`

> worker1
```
somesh@k8s-ha-worker1:~$ sudo docker version
Client: Docker Engine - Community
 Version:           20.10.17
 API version:       1.41
 Go version:        go1.17.11
 Git commit:        100c701
 Built:             Mon Jun  6 23:02:57 2022
 OS/Arch:           linux/amd64
 Context:           default
 Experimental:      true

Server: Docker Engine - Community
 Engine:
  Version:          20.10.17
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.17.11
  Git commit:       a89b842
  Built:            Mon Jun  6 23:01:03 2022
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.6.6
  GitCommit:        10c12954828e7c7c9b6e0ea9b0c02b01407d3ae1
 runc:
  Version:          1.1.2
  GitCommit:        v1.1.2-0-ga916309
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```

> worker2
```
somesh@k8s-ha-worker2:~$ sudo docker version
Client: Docker Engine - Community
 Version:           20.10.17
 API version:       1.41
 Go version:        go1.17.11
 Git commit:        100c701
 Built:             Mon Jun  6 23:02:57 2022
 OS/Arch:           linux/amd64
 Context:           default
 Experimental:      true

Server: Docker Engine - Community
 Engine:
  Version:          20.10.17
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.17.11
  Git commit:       a89b842
  Built:            Mon Jun  6 23:01:03 2022
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.6.6
  GitCommit:        10c12954828e7c7c9b6e0ea9b0c02b01407d3ae1
 runc:
  Version:          1.1.2
  GitCommit:        v1.1.2-0-ga916309
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```