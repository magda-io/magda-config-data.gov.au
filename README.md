# Data.gov.au Magda Config

This is the custom magda config used for running search.data.gov.au. It shows an example of how you can run a high-availability configuration of Magda under GKE.

Keep in mind that Data.gov.au uses a number of services that exist outside Kubernetes and are a bit fiddly to set up - in particularly it uses Let's Encrypt for HTTPS through its domain hosted on Route53 in AWS, a GCE Ingress (which should be automatically provisioned by Google Cloud but often needs some nudging via the console) and Google Cloud SQL postgres (which requires the right secrets to be set up for both a service account and a database user).

# To upgrade
```
helm repo update
# download helm charts dependencies 
helm dep up ./chart
helm upgrade -n dga-prod magda ./chart --timeout 30000s --install -f config.yaml
```

> Magda version should be specified in deploy chart [Chart.yaml](./chart/Chart.yaml) dependencies section.

# Upgrade Guide:

## v2.2.4

also upgrade csw-connector to v2.0.2

## v2.2.3

Minor upgrade


## v2.2.2

This upgrade includes dataset indice version bump, which will trigger a full reindex.
To prevent users from partial result & minimise the downtime, you can set `.Values.datasetsIndexVersion` to previous version `48` until reindex is completed.


## v1.2.0

v1.2.0 comes with Elasticsearch upgrade.

More upgrade / migration info can be found from: [here](https://github.com/magda-io/magda/blob/master/docs/docs/migration/1.2.0.md)

## v1.1.0

v1.1.0 requires upgrading Google Cloud SQL to postgreSQL 13. We used Google DMS for this job.
Steps of upgrading Google Cloud SQL to postgreSQL 13 using Google DMS can be found from [here](https://github.com/magda-io/magda/blob/master/docs/docs/migration/upgrade-google-cloud-sql-using-google-dms.md).

## 0.0.60

v0.0.60 update elasticsearch dataset indice version to 47, which will trigger a full reindex.
To prevent users from partial result & minimise the downtime, you can set `.Values.datasetsIndexVersion` to previous version `46` until reindex is completed.


## 0.0.58-rc.3

In order to minimise the downtime during the migration, we skipped the version 0.0.57 and jumped to RC release 0.0.58-rc.3.

Since 0.0.57, we started to use `local deploy chart` based approach to deploy Magda. We defined Magda components as dependecies in file [Chart.yaml](chart/Chart.yaml). You can specify the version required in the same file as well.

As connectors are moved out from Magda main repo and serves as external extensions now, to add a new connector, you will need:
- add the required connector type as a dependecy in [Chart.yaml](chart/Chart.yaml) and assign an alias to it
- add connector config in [config.yaml](./config.yaml)


During the upgrade, we also upgraded [cert-manager](https://github.com/jetstack/cert-manager) to the latest version 1.02.

## 0.0.56

This is a complicated one. Add

```yaml
  image:
    tag: 0.0.55-RC1
```

... to the config for `search-api` AND `registry-api`, and under `tags:`, change `indexer` to:

```
  indexer: false
```

before running helm upgrade. This is because both the registry db and search indices have changed enough not to be backwards compatible, so we want to keep running the old versions of both APIs while the helm upgrade takes place. If the indexer is allowed to run during this process, it'll create new empty indices and then quit because it can't access the registry anymore, so turn it off before the upgrade.

The DB migration for the registry in this version is incredibly heavy - on staging it takes 5-10 minutes, during which the registry will be mostly unavailable.

Once helm finishes, immediately remove the `image` lines from `registry-api`, turn `indexer` back to `true` and run the helm upgrade again, this time with `--no-hooks`. This will change the registry over to the new version and allow the indexer to start.

Monitor the indexer logs - once it has finished creating new indices for both `regions` and `datasets`, remove the `image` lines from `search-api` also.


## 0.0.55

No elasticsearch upgrades this time, although there has been a slight tweak to the default email templates that you might want to incorporate - the `question.html` email now has a ` {{message.note}}` field that explains why the default email address is getting a message in the event that an email can't be extracted from either the dataset or publisher contact point.

## 0.0.54

This also involves another elasticsearch index upgrade, so add...

```yaml
  image:
    tag: 0.0.53-RC1
```

... to the config for `search-api` before running helm upgrade. Look at the indexer logs, when it's finished indexing then remove those lines and run helm upgrade again.


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
cd terraform/magda
```

```bash
gcloud iam service-accounts keys create key.json --iam-account=$SERVICE_ACCOUNT_EMAIL
```

You will now have a `key.json` file in `terraform/magda`, containing a private key. We suggest you put this somewhere safe like a password manager.
DO **NOT** CHECK IT INTO SOURCE CONTROL.

#### 10. Grant service account permission

5. No need to delete es-data pods manually, helm now does that :tada:.

6. No need to do anything with the cronjobs or cron config, it's all in helm now! :tada:
