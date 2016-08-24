## Manually run Ansible playbooks
### Prerequisites
* `ansible`
* `cfssl`
* `jq`

On a Mac run `brew install ansible cfssl jq`

On packet create 3 etcd servers, 2 master servers and some workers (only CentOS7 has been tested)
Get list for inventory  
`curl -H 'X-Auth-Token: CuUyhwHviRwHxJk3qruZH8ui9V3EN2Rr' https://api.packet.net/projects/001400bb-f3e4-46c1-bbf4-7bbf9ab849ad/devices | jq -r '.devices|=sort_by(.hostname)|.devices[]|.hostname+" ansible_host="+.ip_addresses[0].address+" internal_ipv4="+.ip_addresses[2].address'`

Get list of IPs for TLS  
`curl -H 'X-Auth-Token: CuUyhwHviRwHxJk3qruZH8ui9V3EN2Rr' https://api.packet.net/projects/001400bb-f3e4-46c1-bbf4-7bbf9ab849ad/devices | jq -r '"\""+.devices[]?.ip_addresses[0,2].address+","+"\""'`

* manually modify `inventory.ini` with the hostnames, `ansible_host`=public IPv4 and `internal_ipv4` of the machines you created
* in `../tls/kubernetes-csr.json` replace with the internal and hostnames, external and internal IPv4 for all the nodes in the cluster
* run `./install.sh`

To just run the playbook
`ansible-playbook -i inventory.ini -s kubernetes.yaml --extra-vars "@runtime_vars.yaml"`

### TODO
Manage certs correctly