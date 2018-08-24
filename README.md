# Data.gov.au Magda Config

This is the custom magda config used for running search.data.gov.au. It shows an example of how you can run a high-availability configuration of Magda under GKE.

Keep in mind that Data.gov.au uses a number of services that exist outside Kubernetes and are a bit fiddly to set up - in particularly it uses Let's Encrypt for HTTPS through its domain hosted on Route53 in AWS, a GCE Ingress (which should be automatically provisioned by Google Cloud but often needs some nudging via the console) and Google Cloud SQL postgres (which requires the right secrets to be set up for both a service account and a database user).

# Migrating from the previous, bundled-into-the-same repository version of Magda data.gov.au

1. Delete stuff that wasn't managed by helm that we'll need to replace with stuff that now is.

```bash
kubectl delete cronjobs --all
kubectl delete configmap connector-config
```

2. Add the magda chart repo to helm
```bash
helm repo add magda-io https://charts.magda.io

# "magda-io" has been added to your repositories
```

3. Install magda. The `--devel` flag allows us to install the latest RC version
```bash
helm upgrade magda magda-io/magda --wait --timeout 30000 --install -f config.yaml --devel
```

This will take a while for it to get everything set up. If you want to watch progress, run `kubectl get pods -w` in another terminal.

7. Once helm is finished, run `kubectl get services -w` and wait for `gateway` to receive an external IP. It'll look something like this:

```
gateway                           LoadBalancer   10.102.57.74     123.456.789.123     80:31519/TCP        1m
```

At this point you should be able to go to http://<external ip> in your browser and see the Magda UI. Note that the search won't work until it's finished indexing regions - to see the progress of this, run `kubectl logs -f -lservice=indexer`. Unless you've got a lot of processing power this will take quite a while - sorry! We're working on making it better.

8. 
