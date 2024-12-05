kubectl create namespace portainer
helm repo add portainer https://portainer.github.io/k8s/
helm repo update


helm upgrade -i -n portainer portainer portainer/portainer \
    --set service.type=LoadBalancer \
    --set service.httpPort=80 \
    --set persistence.enabled=true \
    --set persistence.size=10Gi \
    --set persistence.storageClass=longhorn