# WASM Extension Prototype

This project demonstrates using WASM extensions with Consul on Kubernetes.

## Requirements
- `kind`
- `consul`
  - Enterprise dev build for Envoy extensions
- `consul-k8s`
  - Local file support requires a custom `consul-k8s-control-plane` image so it can mount wasm plugins.

## Usage

This section is _mostly_ in order.

### Create k8s cluster

This command executes a script that runs a local docker registry and creates a `kind` cluster that can pull images from that registry.

```shell
./kind-with-rgy
```

### Build Consul Enterprise

This is only necessary while the Wasm extension work is in progress.
Need to be able to pull dev images.
This will be unnecessary once consul has been updated.

```shell
cd consul-enterprise/
make dev-docker
docker tag consul-dev localhost:5000/consul-dev-ent
docker push localhost:5000/consul-dev-ent
```

or

```shell
( cd ~/github.com/hashicorp/consul-enterprise/ && make dev-docker && docker tag consul-dev localhost:5000/consul-dev-ent && docker push localhost:5000/consul-dev-ent )
```

### Build consul-k8s-control-plane

Had to hack up the sidecar injector for the dataplane so that it mounts the `consul-extensions` volume to access the .wasm files.

**Note that this is for local file support only**

```shell
cd consul-k8s
make control-plane-dev-docker
docker tag consul-k8s-control-plane-dev localhost:5000/consul-k8s-control-plane-dev
docker push localhost:5000/consul-k8s-control-plane-dev
```

### Secrets

```shell
rm -rf secrets
mkdir secrets
echo -n "1111111-2222-3333-4444-555555555555" > secrets/root-token.txt
echo -n "$(consul keygen)" > secrets/gossip-key.txt
(cd secrets ; consul tls ca create)
chmod 600 secrets/*
```

#### Create a k8s secret for the Consul data

```shell
kubectl create secret generic consul \
  --from-file=root-token=secrets/root-token.txt \
  --from-file=gossip-key=secrets/gossip-key.txt \
  --from-file=ca-cert=secrets/consul-agent-ca.pem \
  --from-file=ca-key=secrets/consul-agent-ca-key.pem \
  --from-file=enterprise-license=${CONSUL_LICENSE_PATH}
```

### Configure Volume for supplying the WASM plugin for the applications

```shell
kc apply -f pv/pv.yaml
kc apply -f pv/pvc.yaml
```

### Install Consul

```shell
consul-k8s install -config-file values.yaml -namespace default -auto-approve
```

### Configure the Consul CLI

```shell
export CONSUL_HTTP_TOKEN='1111111-2222-3333-4444-555555555555'
export CONSUL_HTTP_ADDR=localhost:8501
export CONSUL_HTTP_SSL=true
export CONSUL_HTTP_SSL_VERIFY=false
```

### Test out the Consul install

```shell
kubectl port-forward services/consul-server 8501
```

In a separate terminal

```shell
consul catalog services
```

### Install the apps

```shell
kubectl apply -f apps/api.yaml
kubectl apply -f apps/web.yaml
kubectl apply -f apps/intentions.yaml
consul config write apps/api.hcl
consul config write apps/web.hcl
```

### Test out the app

```shell
export API_APP=$(kubectl get pods | grep 'api-' | awk '{print $1}')
export WEB_APP=$(kubectl get pods | grep 'web-' | awk '{print $1}')
```

```shell
kubectl exec -it pod/$WEB_APP -c web -- ash

# good actor
curl 'http://api.default.svc.cluster.local/products?type=coffee'

# bad actor - attempted SQL injection
curl 'http://api.default.svc.cluster.local/products?type=coffee;%20--%20WHERE%201=1'
```

### Add the Envoy extension to the `api` app

```shell
code apps/api-with-waf.hcl
consul config write apps/api-with-waf.hcl
```

### Show the HTTP filter config

```shell
kubectl port-forward pods/$API_APP 19000

# In a new terminal
curl localhost:19000/config_dump
```

### Test out the app and show the extension working

```shell
kubectl exec -it pod/$WEB_APP -c web -- ash

# good actor
curl 'http://api.default.svc.cluster.local/products?type=coffee'

# bad actor - attempted SQL injection
curl 'http://api.default.svc.cluster.local/products?type=coffee;%20--%20WHERE%201=1'
```

### Clean up

```shell
kind delete cluster
docker stop kind-registry
```
