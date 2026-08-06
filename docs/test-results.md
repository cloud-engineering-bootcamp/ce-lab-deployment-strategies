# Test Results — Lab M5.06

Captured 2026-08-06. Terraform v1.x, AWS provider v5.x, account `697345203222`,
region `us-east-1`.

## Static Validation

```
$ terraform fmt -check -recursive
Exit code: 0

$ terraform validate
Success! The configuration is valid.

$ python -c "import json; json.load(open('deployment.json'))"
deployment.json: valid JSON
```

## Infrastructure Apply

```
aws_s3_bucket.blue: Creation complete after 3s [id=deploy-lab-draian123-blue]
aws_s3_bucket.green: Creation complete after 3s [id=deploy-lab-draian123-green]
aws_s3_bucket_public_access_block.blue: Creation complete after 1s
aws_s3_bucket_public_access_block.green: Creation complete after 1s
aws_s3_bucket_website_configuration.blue: Creation complete after 1s
aws_s3_bucket_website_configuration.green: Creation complete after 1s
aws_s3_bucket_policy.blue: Creation complete after 0s
aws_s3_bucket_policy.green: Creation complete after 0s

Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

blue_bucket_name  = "deploy-lab-draian123-blue"
blue_website_url  = "http://deploy-lab-draian123-blue.s3-website-us-east-1.amazonaws.com"
green_bucket_name = "deploy-lab-draian123-green"
green_website_url = "http://deploy-lab-draian123-green.s3-website-us-east-1.amazonaws.com"
```

## Both Environments Serve Distinct Content

Content uploaded with `aws s3 cp ... --content-type "text/html"`, then each endpoint
was fetched and the badge and version string extracted from the returned HTML:

```
blue  -> HTTP 200 | BLUE Environment  | Version 1.0.0 | http://deploy-lab-draian123-blue.s3-website-us-east-1.amazonaws.com
green -> HTTP 200 | GREEN Environment | Version 2.0.0 | http://deploy-lab-draian123-green.s3-website-us-east-1.amazonaws.com
```

Both return HTTP 200, and the two pages differ in badge text, version, and accent colour
(`#0077b6` blue vs `#2d6a4f` green) — satisfying the "both environments serve distinct
content" success criterion.

## Deployment Lifecycle

Initial state committed to the repo:

```json
{
  "active_environment": "blue",
  "version": "1.0.0",
  "deployed_by": "initial-setup",
  "history": [ { "environment": "blue", "version": "1.0.0", "action": "initial-deploy" } ]
}
```

<!-- LIFECYCLE-RESULTS -->

## Summary

| Check | Status |
|---|---|
| `terraform fmt -check -recursive` | PASS |
| `terraform validate` | PASS |
| `terraform apply` — 8 resources | PASS |
| Blue website reachable (HTTP 200) | PASS |
| Green website reachable (HTTP 200) | PASS |
| Blue and green serve distinct content | PASS |
| `deployment.json` valid and tracking `blue` | PASS |
| Deploy workflow — blue → green | pending workflow run |
| Rollback workflow — green → blue | pending workflow run |
