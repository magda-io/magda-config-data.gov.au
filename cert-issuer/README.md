Before you install this chart install `cert-manager` by following instruction here: 

https://cert-manager.io/docs/installation/kubernetes/

We now (since June 2024) use Google Cloud DNS and authenticated via [Workload Identity Federation for GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity). 

To setup, please refer to the following docs:
- https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity
- https://cert-manager.io/docs/configuration/acme/dns01/google/


Then finally install:

```
helm upgrade --install --namespace cert-issuer cert-issuer ./cert-issuer --set acmeEmail=CHANGEME,useStaging=SHOULDIUSESTAGING
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| accessKeyID | string | `nil` |  |
| acmeEmail | string | `nil` |  |
| useStaging | bool | `true` |  |