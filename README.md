# Data.gov.au Magda Config

This is the custom magda config used for running search.data.gov.au. It shows an example of how you can run a high-availability configuration of Magda under GKE.

Keep in mind that Data.gov.au uses a number of services that exist outside Kubernetes and are a bit fiddly to set up - in particularly it uses Let's Encrypt for HTTPS through its domain hosted on Route53 in AWS, a GCE Ingress (which should be automatically provisioned by Google Cloud but often needs some nudging via the console) and Google Cloud SQL postgres (which requires the right secrets to be set up for both a service account and a database user).

# To upgrade
```
helm repo update
helm upgrade magda magda-io/magda --wait --timeout 30000 --install -f config.yaml --version=<INSERT VERSION HERE (e.g. "0.0.49-RC2")>
```

# Upgrade Guide:

## 0.0.50
Before helm upgrade:
- Run https://github.com/magda-io/magda-config-data.gov.au/blob/master/sql-migrations/add-email-templates.sql in order to create the email templates
- Run https://github.com/magda-io/magda-config-data.gov.au/blob/master/sql-migrations/add-navigation-items.sql in order to create navigation menu items
- Run https://github.com/magda-io/magda-config-data.gov.au/blob/master/sql-migrations/add-static-pages.sql to add static pages
- Run https://github.com/magda-io/magda-config-data.gov.au/blob/master/sql-migrations/add-home-content.sql.sql to add home content items
- Run `sql-migrations/add-third-party-js.sql` in `content-db` to add the old third party js code.

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

4. No need to delete es-data pods manually, helm now does that :tada:.

5. No need to do anything with the cronjobs or cron config, it's all in helm now! :tada:
