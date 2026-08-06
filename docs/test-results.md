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

### 1. Deploy & Switch — run [31084537174](https://github.com/Draian123/ce-lab-deployment-strategies/actions/runs/31084537174)

Triggered via `workflow_dispatch` from the Actions tab with `version = 2.0.0`.
**Conclusion: success**, 15 seconds.

The workflow read `active_environment = blue`, therefore targeted **green**, uploaded
`app/green/index.html` to `deploy-lab-draian123-green`, health-checked the endpoint,
and only then switched the pointer.

Resulting `deployment.json` (commit `091cbbf` — "Deploy v2.0.0 to green"):

```json
{
  "active_environment": "green",
  "last_deployed": "2026-08-06T08:21:18Z",
  "deployed_by": "Draian123",
  "version": "2.0.0",
  "history": [
    { "environment": "blue",  "version": "1.0.0", "timestamp": "2026-02-26T10:00:00Z", "action": "initial-deploy" },
    { "environment": "green", "version": "2.0.0", "timestamp": "2026-08-06T08:21:18Z", "action": "deploy-switch" }
  ]
}
```

`active_environment` flipped **blue → green**, `version` advanced to 2.0.0, `deployed_by`
captured the triggering actor, and a `deploy-switch` entry was appended to `history`.

### 2. Rollback — run [31084654683](https://github.com/Draian123/ce-lab-deployment-strategies/actions/runs/31084654683)

Triggered with `reason = "Testing rollback procedure"`. **Conclusion: success.**

No content was uploaded and no infrastructure changed — blue was still running the whole
time, so the rollback is purely a pointer flip. The previous version was read from
`history[-2]`.

Resulting `deployment.json` (commit `ec7e4a7` — "Rollback to blue (v1.0.0)"):

```json
{
  "active_environment": "blue",
  "last_deployed": "2026-08-06T08:22:57Z",
  "deployed_by": "Draian123",
  "version": "1.0.0",
  "history": [
    { "environment": "blue",  "version": "1.0.0", "timestamp": "2026-02-26T10:00:00Z", "action": "initial-deploy" },
    { "environment": "green", "version": "2.0.0", "timestamp": "2026-08-06T08:21:18Z", "action": "deploy-switch" },
    { "environment": "blue",  "version": "1.0.0", "timestamp": "2026-08-06T08:22:57Z", "action": "rollback",
      "reason": "Testing rollback procedure" }
  ]
}
```

`active_environment` reverted **green → blue**, `version` reverted to 1.0.0, and the
rollback reason was recorded in `history`.

### Audit trail

Both workflows committed and pushed their state change, so the deployment history is
visible in `git log` as well as in the JSON:

```
ec7e4a7 Rollback to blue (v1.0.0)
091cbbf Deploy v2.0.0 to green
fbb86ab Lab M5.06: Blue/Green Deployment Strategies
```

Elapsed time from deploy to completed rollback: **1 minute 39 seconds** — comfortably
inside the "rollback takes under a minute" target from the lab scenario, since the
rollback itself ran in seconds.

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
| Deploy workflow — targets inactive env, health-checks, switches blue → green | PASS |
| Deploy workflow — commits updated state back to `main` | PASS |
| Rollback workflow — reverts green → blue with reason recorded | PASS |
| Rollback workflow — commits updated state back to `main` | PASS |
| `history` records all three actions with timestamps | PASS |
