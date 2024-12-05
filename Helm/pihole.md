helm repo add mojo2600 https://mojo2600.github.io/pihole-kubernetes/
helm repo update

kubectl create namespace pihole
helm upgrade --install pihole mojo2600/pihole --namespace pihole \
--set DNS1=8.8.8.8 \
--set DNS2=8.8.4.4 \
--set serviceWeb.type=LoadBalancer \
--set serviceWeb.loadBalancerIP=192.168.3.231 \
--set persistentVolumeClaim.enabled=true \
--set persistentVolumeClaim.size=500Mi \
--set persistentVolumeClaim.accessModes[0]=ReadWriteOnc



radera

helm uninstall pihole --namespace pihole
helm repo remove mojo2600
kubectl delete namespace pihole
kubectl get all --namespace pihole
kubectl get namespaces
