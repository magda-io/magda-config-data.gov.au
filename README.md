# Data.gov.au Magda Config

This is the custom magda config used for running search.data.gov.au. It shows an example of how you can run a high-availability configuration of Magda under GKE.

Keep in mind that Data.gov.au uses a number of services that exist outside Kubernetes and are a bit fiddly to set up - in particularly it uses Let's Encrypt for HTTPS through its domain hosted on Route53 in AWS, a GCE Ingress (which should be automatically provisioned by Google Cloud but often needs some nudging via the console) and Google Cloud SQL postgres (which requires the right secrets to be set up for both a service account and a database user).

# To upgrade
```
helm repo update
helm upgrade magda magda-io/magda --wait --timeout 30000 --install -f config.yaml --version=<INSERT VERSION HERE (e.g. "0.0.49-RC2")>
```

# Upgrade Guide:

## 0.0.53

Run `sql-migrations/add-favicon.sql` in the content-db first, then `helm upgrade` as usual.

This also involves an elasticsearch index upgrade, so add...

```yaml
  image:
    tag: 0.0.52-RC2
```

... to the config for `search-api` before running helm upgrade. Look at the indexer logs, when it's finished indexing then remove those lines and run helm upgrade again.

## 0.0.52

Nothing special this time, just helm upgrade as usual

## 0.0.51

This moves the readiness check for gateway, which doesn't propagate properly into the GKE health check. Before you start, turn the GKE health check up to 300 second intervals and 10 unhealthy threshold to give yourself some time.

This version includes a pretty serious regions index upgrade, which requires a new elasticsearch upgrade before the search-api OR indexer can be upgraded. So...

1. Add to the config for `search-api` AND `indexer`:

```yaml
  image:
    tag: 0.0.50-RC3
```

2. Open the GCE health check page ready to quickly change it! To give yourself more time, change the failure threshold and timeout to as long as you can make it.

3. Run `helm upgrade` as above.

4. (while helm upgrade is running) Change the health check URL in GCE over to `/status/live`.

5. (while helm upgrade is running) Run `kubectl edit deployment search-api` and manually edit the readiness and liveness check urls to `/v0/datasets`.

6. Wait for helm upgrade to finish.

7. Use `kubectl port-forward <kibana pod id> 5601` to connect to kibana and `GET /_cluster/health` to make sure everything's finished initializing. 

8. Remove the image tag from the `indexer` config, run `helm upgrade` again with `--no-hooks` and wait for it to finish indexing the new regions index

9. Remove the `image.tag` declaration from the config from `search-api` and `helm upgrade` with `--no-hooks` again

10. Use `kubectl edit` to change the readiness/liveness check for search-api back to their usual values in search-api/deployment.yaml

11. Restore the normal values in the health check for failure threshold and timeout (should be 70 seconds and 10 failures).

## 0.0.50
Before helm upgrade:
In the content db:
- Run https://github.com/magda-io/magda-config-data.gov.au/blob/master/sql-migrations/add-email-templates.sql in order to create the email templates
- Run https://github.com/magda-io/magda-config-data.gov.au/blob/master/sql-migrations/add-navigation-items.sql in order to create navigation menu items
- Run https://github.com/magda-io/magda-config-data.gov.au/blob/master/sql-migrations/add-static-pages.sql to add static pages
- Run https://github.com/magda-io/magda-config-data.gov.au/blob/master/sql-migrations/add-home-content.sql to add home content items
- Run https://github.com/magda-io/magda-config-data.gov.au/blob/master/sql-migrations/add-third-party-js.sql to add the old third party js code.
- Run https://github.com/magda-io/magda-config-data.gov.au/blob/master/sql-migrations/add-initial-translations.sql to make sure the content of the suggest dataset email doesn't change and the app name stays the same
- Run https://github.com/magda-io/magda-config-data.gov.au/blob/master/sql-migrations/add-footer-config.sql to change up footer items

Run `kubectl apply -f role-binding.yaml` to make the admin api work.

This version includes a datasets index upgrade, so add...

```yaml
  image:
    tag: 0.0.49-RC3
```

... to the config for `search-api` before running helm upgrade. Look at the indexer logs, when it's finished indexing then remove those lines and run helm upgrade again.

This also makes the change from the web client getting content from the CMS, so you'll need to do that for web-server too.

## 0.0.49
Because the CSS now comes from the `content-api`, we need to insert the correct SQL before upgrading or the page will be unstyled until the upgrade is finished. You can find a script to insert it in `sql-migrations/add-stylesheet-to-content-api.sql`. Run this against the content-db.

## Migrating from the previous, bundled-into-the-same repository version of Magda data.gov.au

1. Delete stuff that wasn't managed by helm that we'll need to replace with stuff that now is.

```bash
kubectl delete cronjobs --all
kubectl delete configmap connector-config
```

2. Add secrets for config-db
```bash
kubectl edit secret db-passwords
```

3 Add the magda chart repo to helm
```bash
helm repo add magda-io https://charts.magda.io

# "magda-io" has been added to your repositories
```

4. Install magda. The `--devel` flag allows us to install the latest RC version
```bash
helm upgrade magda magda-io/magda --wait --timeout 30000 --install -f config.yaml --devel
```

This will take a while for it to get everything set up. If you want to watch progress, run `kubectl get pods -w` in another terminal.

5. No need to delete es-data pods manually, helm now does that :tada:.

6. No need to do anything with the cronjobs or cron config, it's all in helm now! :tada:
