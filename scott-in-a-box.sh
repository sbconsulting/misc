#!/bin/bash
#
# Copyright 2017-present Open Networking Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -xe

# This script assumes the following repos exist
# ~/cord/automation-tools
# ~/cord/helm-charts

# Location of 'cord' directory checked out on the local system
CORDDIR="${CORDDIR:-${HOME}/cord}"

# Install K8S, Helm, Openstack
"$CORDDIR"/automation-tools/openstack-helm/openstack-helm-dev-setup.sh


# VTN requirements
POD=$( kubectl get pod --namespace openstack|grep openvswitch-db|awk '{print $1}' )
kubectl --namespace openstack exec "$POD" \
    -- ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:6641

cd "$CORDDIR"/helm-charts
helm upgrade --install onos-cord ./onos
~/openstack-helm/tools/deployment/common/wait-for-pods.sh default

# Add keys for VTN
[ ! -e ~/.ssh/id_rsa ] && ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ""
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
ONOS_CORD_POD=$(kubectl get pods | grep onos-cord | awk '{print $1}')
kubectl cp ~/.ssh/id_rsa "$ONOS_CORD_POD":/root/node_key

# Add dummy fabric interface
sudo modprobe dummy
sudo ip link set name fabric dev dummy0
sudo ifconfig fabric up


# Install charts for M-CORD
helm dep update ./xos-core
helm upgrade --install xos-core ./xos-core -f examples/image-tag-candidate.yaml -f examples/imagePullPolicy-IfNotPresent.yaml
~/openstack-helm/tools/deployment/common/wait-for-pods.sh default

helm dep update ./xos-profiles/base-openstack
helm upgrade --install base-openstack ./xos-profiles/base-openstack \
    --set computeNodes.master.name="$( hostname )" \
    --set vtn-service.sshUser="$( whoami )" \
    -f examples/image-tag-candidate.yaml -f examples/imagePullPolicy-IfNotPresent.yaml
~/openstack-helm/tools/deployment/common/wait-for-pods.sh default

#helm dep update ./xos-profiles/mcord
#helm upgrade --install mcord ./xos-profiles/mcord
#~/openstack-helm/tools/deployment/common/wait-for-pods.sh default


# Firewall VNC ports for security
#sudo ufw default allow incoming
#sudo ufw default allow outgoing
#sudo ufw default allow routed
#sudo ufw deny proto tcp from any to any port 5900:5950 comment 'vnc'
#sudo ufw enable


#echo "M-CORD has been successfully installed"

sudo iptables -I INPUT 1 -p tcp --dport 5900:5999 -j DROP
sudo iptables -I INPUT 1 -p tcp -s 71.238.116.61 --dport 5900:5999 -j ACCEPT

echo "Done!"
