# Argo Offline

Collect every resou6rce necessary to install an offline version of Argo products.

## Dependencies

* make
* Git
* Docker
* yq
* Python 3.6+
* Helm (for installation)

## How to use

### Downloading resources

Run `make archive` and you're all set.  
This command will generate a `dist` directory with the artifacts needed including:
* `argo-helm` - Clone of Argo helm charts repository
* `argo.tar` - An archive with all the necessary docker images
* `images.txt` - A list with all the downloaded images (keep it)

### Deploying artifacts

1. On offline network, run `make load retag push TARGET_REGISTRY=your.registry.name` to load and push the docker images.
2. Manually adjust the `values.yaml` files to reference your registry
3. `helm install` the desired helm charts
