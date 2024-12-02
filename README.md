# Ray Custom Docker

This example goes over how to build your own custom docker image and use it in a `ray`
cluster.




```sh
# building the docker image
docker build -t raytest:0.1.0 .

# set up the kind cluster
kind create cluster
kind load docker-image raytest:0.1.0

# add the necessary ray operator
helm install kuberay-operator kuberay/kuberay-operator --version 1.2.2

# spin up a cluster, using the image we just built
helm install raycluster kuberay/ray-cluster --version 1.2.2 --set-json='image.repository="raytest"' --set-json='image.tag="0.1.0"'

# test that it's working (nushell syntax - you would use export HEAD_POD="$()" syntax with other shells)
$env.HEAD_POD = (kubectl get pods --selector=ray.io/node-type=head -o custom-columns=POD:metadata.name --no-headers)
kubectl exec -it $env.HEAD_POD -- python -c "import ray; ray.init(); print(ray.cluster_resources())"

# cleanup
helm uninstall raycluster
helm uninstall kuberay-operator
kind delete cluster
```
