# Getting Started on an Existing Kubernetes Instance
Before you start you need to get a Kubernetes cluster. If you just want to give this a try locally, you can use [Docker for Desktop](https://www.docker.com/products/docker-desktop), [Minikube](https://kubernetes.io/docs/setup/minikube/) or [k3d](). Either way make sure the VM has at least 2 CPUs and 6GB of RAM. Alternatively you can run this in the cloud - we use [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/). Make sure that whatever you use has a Kubernetes version of no higher than 1.15 at this point - we'll support higher versions in the next release.

1. Install [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) and [helm 3](https://github.com/helm/helm/releases).

2. Fork this repository - this means you can make your own customisations, but still pull in updates.

3. `git clone` it to your local machine open a terminal in the directory

4. Install [kubernetes-replicator](https://github.com/mittwald/kubernetes-replicator) to your cluster (as per [instructions here](https://github.com/magda-io/magda/blob/master/docs/docs/building-and-running.md#install-kubernetes-replicator)) if you haven't done so.

5. Look at [values.yaml](./chart/values.yaml) and make sure to customise the uncommented lines. Everything else can be left as default for now.

6. Run the create secrets script in a command line and follow the prompts
```bash
    ./create-secrets/index-linux
    # OR
    ./create-secrets/index-macos
    # OR
    create-secrets\index.win.exe
```
You need to unset your `NODE_OPTIONS` env variable if you run into `Pkg: FLAGS_MISMATCH` while running the secrets script.

Output should look something like so:
```
magda-create-secrets tool 
? Are you creating k8s secrets for google cloud or local testing cluster? Local Testing Kubernetes Cluster
? Which local k8s cluster environment you are going to connect to? docker
? Do you need to access SMTP service for sending data request email? YES
? Please provide SMTP service username: abc
? Please provide SMTP service password: def
? Do you want to create google-client-secret for oAuth SSO? NO
? Do you want to create facebook-client-secret for oAuth SSO? NO
? Do you want to manually input the password used for databases? Generated password: up3Saeshusoequoo
? Specify a namespace or leave blank and override by env variable later? YES (Specify a namespace)
? What's the namespace you want to create secrets into (input `default` if you want to use the `default` namespace)? default
? Do you want to allow environment variables (see --help for full list) to override current settings at runtime? YES (Any environment variable can ove
ride my settings)
? Do you want to connect to kubernetes cluster to create secrets now? YES (Create Secrets in Cluster now)
Successfully created secret `smtp-secret` in namespace `default`.
Successfully created secret `db-passwords` in namespace `default`.
Successfully created secret `auth-secrets` in namespace `default`.
All required secrets have been successfully created!
```

**Optional:** If you're going to be triggering connector jobs from the admin-api (used by the admin UI), create the role binding this needs:

```bash
kubectl apply -f role-binding.yaml
```

7. Add the magda chart repo to helm
```bash
helm repo add magda-io https://charts.magda.io
```

8. Build the local chart
```bash
helm dep up ./chart
```

9. Install magda
```bash
helm upgrade --install --timeout 9999s --debug --wait magda ./chart
```

This will take a while for it to get everything set up.

10. Connect to your instance:
- **On the cloud or docker for desktop** Once helm is finished, run `kubectl get services -w` and wait for `gateway` to receive an external IP. It'll look something like this on kubectl or docker for desktop.
- **On minikube**, you'll just have to run `minikube ip` and keep refreshing it with the node port below until it comes up.

```
gateway                           LoadBalancer   10.102.57.74     123.456.789.123     80:31519/TCP        1m
```

At this point you should be able to go to `http://<external ip>` in your browser and see the Magda UI. If you're not able to make this work, you should be able to run `kubectl port-forward <gateway pod id> 30100:80` to make the service available on port 30100.

Note that the search won't work until it's finished indexing regions - to see the progress of this, run `kubectl logs -f -lservice=indexer`. Unless you've got a lot of processing power this will take quite a while - sorry! We're working on making it better.

By default, data.gov.au will be crawled on startup so you'll start with some data.

# To update
1. Merge the latest from this repository into yours.
2. Run:
```bash
helm repo update
```

3. Run:
```
helm upgrade --install --timeout 9999s --debug --wait magda ./chart
```
