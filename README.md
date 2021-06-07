#### docker build + run
```
docker build -f Dockerfile . -t seanturner026/kube-playground-http-server
docker run -p 3000:3000 seanturner026/kube-playground-http-server
```

#### eks kube config fetch
```
aws eks update-kubeconfig --name kube-playground
```

#### cluster autoscaler
```
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
helm install cluster-autoscaler --namespace kube-system autoscaler/cluster-autoscaler --values ./helm/cluster_autoscaler_chart_values.yaml
```

#### metrics server
```
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl get deployment metrics-server -n kube-system
```

#### prometheus
```
kubectl create namespace prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade -i prometheus prometheus-community/prometheus \
    --namespace prometheus \
    --set alertmanager.persistentVolume.storageClass="gp2",server.persistentVolume.storageClass="gp2"
kubectl get pods -n prometheus
kubectl --namespace=prometheus port-forward deploy/prometheus-server 9090
```

#### aws load balancer controller
```
helm repo add eks https://aws.github.io/eks-charts
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=kube-playground --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
```

#### go http server deployment
```
kubectl create namespace prometheus
kubectl apply -f ./kube/
```
