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

#### aws load balancer controller
```
helm repo add eks https://aws.github.io/eks-charts
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=kube-playground --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
```

#### go http server deployment
```
k apply -f ./kube/namespace.yaml
k apply -f ./kube/
```
