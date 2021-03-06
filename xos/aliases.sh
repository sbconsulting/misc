#! /bin/bash
alias cdgr="cd ~/projects/gopath/src/github.com/opencord"
alias helm-cycle="/opt/smbaker/helm-cycle.sh"
alias helm-xossh-start="kubectl get pods | grep -i xossh | grep -v "erminating" > /dev/null || (pushd ~/cord/helm-charts; helm install xos-tools/xossh -f examples/xossh-candidate.yaml -n xossh; popd)"
alias helm-xossh-stop="helm del --purge xossh"
alias helm-xossh="~/cord/helm-charts/xos-tools/xossh/xossh-attach.sh"
alias helm-wait="/opt/smbaker/helm-wait.sh"
alias helm-tosca="/opt/smbaker/helm-tosca.sh"
alias helm-tosca-node="/opt/smbaker/helm-tosca-node.sh"
alias helm-onos="/opt/smbaker/helm-onos.sh"
alias helm-kafkacat="/opt/smbaker/helm-kafkacat.sh"
alias dockerfile-revert="python /opt/smbaker/dockerfile-revert.py"
alias dockerfile-candidates="python /opt/smbaker/dockerfile-candidates.py"
alias dockerfile-VERSION="bash /opt/smbaker/dockerfile-VERSION.sh"
alias rebuild-local="bash /opt/smbaker/rebuild-local.sh"
alias push-candidates="bash /opt/smbaker/push-candidates.sh"
alias upkube="source /opt/smbaker/upkube.sh"

dosfix() {
    echo fixing $1
    sed -i 's/\r//' $1 && sed -i 's/[ \t]*$//' $1
}
