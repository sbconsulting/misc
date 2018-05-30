#! /bin/bash

USE_PROFILE=${PROFILE:-rcord-lite}

echo "Profile is $USE_PROFILE"

#helm delete $USE_PROFILE
#helm delete xos-core
#helm delete xossh
helm del --purge $USE_PROFILE
helm del --purge xos-core
helm del --purge xossh
helm del --purge cord-kafka

kubectl delete pods --all
kubectl delete configmaps --all

echo "Waiting for all pods to be deleted..."
GET_PODS_RESULT=`kubectl get pods`
while [ -n "$GET_PODS_RESULT" ]; do
   GET_PODS_RESULT=`kubectl get pods`
done
echo "We are clear of pods"

set -e
cd ~/cord/build

which minikube
if [[ $? == 0 ]]; then 
    docker_env=`minikube docker-env`
    if [[ "$docker_env" != "'none' driver does not support 'minikube docker-env' command" ]]; then
      eval $docker_env
    fi
fi

scripts/imagebuilder.py -f ~/cord/helm-charts/examples/filter-images.yaml

cd ~/cord/helm-charts
helm dep update xos-core
helm install xos-core -n xos-core \
     --set computeNodes.master.name="$( hostname )" \
     --set vtn-service.sshUser="$( whoami )" \
     -f examples/image-tag-candidate.yaml -f examples/imagePullPolicy-IfNotPresent.yaml
helm dep update xos-profiles/$USE_PROFILE
helm install xos-profiles/$USE_PROFILE -n $USE_PROFILE -f examples/image-tag-candidate.yaml -f examples/imagePullPolicy-IfNotPresent.yaml

helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm install --name cord-kafka --set replicas=1 incubator/kafka