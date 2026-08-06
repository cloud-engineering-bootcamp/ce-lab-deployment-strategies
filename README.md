# Lab M5.06 - Deployment Strategies (Blue/Green)

**Cloud Engineering Bootcamp — Week 5, Module 5: Cloud Automation & CI/CD**

Zero-downtime blue/green deployment for an S3-hosted status page, with an explicit
deployment state file, a deploy-and-switch workflow, and instant rollback.

## Architecture

Two identical S3 static website buckets act as deployment targets. Both are always
running; exactly one is "active" at any moment, and `deployment.json` is the single
source of truth for which.

```
                     deployment.json
                  { "active_environment" }
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
    ┌───────────────────┐       ┌───────────────────┐
    │  BLUE  (v1.0.0)   │       │  GREEN (v2.0.0)   │
    │  S3 website       │       │  S3 website       │
    │  always running   │       │  always running   │
    └───────────────────┘       └───────────────────┘
       deploy target when          deploy target when
         green is active             blue is active
```

| Environment | Bucket | URL |
|---|---|---|
| Blue | `deploy-lab-draian123-blue` | http://deploy-lab-draian123-blue.s3-website-us-east-1.amazonaws.com |
| Green | `deploy-lab-draian123-green` | http://deploy-lab-draian123-green.s3-website-us-east-1.amazonaws.com |

> **These URLs are no longer live.** The infrastructure was applied, both environments were
> verified serving distinct content, the full deploy → rollback lifecycle was exercised
> against them, and then everything was torn down with `terraform destroy` to avoid leaving
> public buckets running indefinitely. Captured evidence from while they were live —
> HTTP status codes, page content, and both workflow runs — is in
> [`docs/test-results.md`](docs/test-results.md). Run `terraform apply` to recreate them.

> **Naming note:** S3 bucket names are globally unique across *all* AWS accounts, so the
> lab's plain `deploy-lab` prefix collides with other students. `var.project_name` is set
> to `deploy-lab-draian123`, and the same value is set as `PROJECT_NAME` in both workflows
> so the bucket name is derived in one place rather than hardcoded per step.

## Infrastructure (`main.tf`)

Eight resources, four per environment:

| Resource | Purpose |
|---|---|
| `aws_s3_bucket` | The bucket itself, tagged `Environment = blue\|green` |
| `aws_s3_bucket_website_configuration` | Static hosting, `index.html` as both index and error document |
| `aws_s3_bucket_public_access_block` | All four blocks set to `false` so a public read policy is permitted |
| `aws_s3_bucket_policy` | `s3:GetObject` for `Principal = "*"`, `depends_on` the access block |

The `depends_on` matters: without it Terraform can race and attach the public policy
before the access block is relaxed, and AWS rejects it.

## Deployment State (`deployment.json`)

```json
{
  "active_environment": "blue",
  "last_deployed": "2026-02-26T10:00:00Z",
  "deployed_by": "initial-setup",
  "version": "1.0.0",
  "history": [ { "environment": "...", "version": "...", "timestamp": "...", "action": "..." } ]
}
```

Keeping this in Git rather than in Terraform state or SSM means the active environment is
reviewable, diffable, and auditable — every switch is a commit with an author and a reason.
The `history` array is append-only and drives rollback.

## Workflows

### Deploy & Switch (`.github/workflows/deploy.yml`)

Manual `workflow_dispatch` with a `version` input. Six steps:

1. **Determine target** — reads `.active_environment`, picks the *other* one
2. **Get bucket name** — `${PROJECT_NAME}-${TARGET}`
3. **Deploy** — `aws s3 cp app/$TARGET/index.html s3://$BUCKET/index.html`
4. **Verify** — `curl` the target's website endpoint, abort on anything but HTTP 200
5. **Switch** — `jq` rewrites `active_environment`, `version`, `deployed_by`, `last_deployed`, and appends to `history`
6. **Commit** — pushes the updated `deployment.json` back to `main`

The health check sits *between* deploy and switch. That ordering is the whole point of
blue/green: a broken build fails the check while it is still on the inactive environment,
so live traffic never sees it.

### Rollback (`.github/workflows/rollback.yml`)

Manual `workflow_dispatch` with a required `reason` input. No redeployment happens — the
previous environment is still running untouched, so rollback is purely a pointer flip:

1. Read `active_environment`; refuse if `history` has fewer than 2 entries
2. Flip to the opposite environment, read the previous version from `history[-2]`
3. Append a `rollback` entry recording the reason
4. Commit and push

This is why blue/green rollback is measured in seconds: nothing is rebuilt, re-uploaded, or
re-provisioned.

## Running It

```bash
terraform init
terraform apply -auto-approve

aws s3 cp app/blue/index.html  s3://$(terraform output -raw blue_bucket_name)/index.html  --content-type "text/html"
aws s3 cp app/green/index.html s3://$(terraform output -raw green_bucket_name)/index.html --content-type "text/html"
```

Both workflows need `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as repository secrets
(*Settings → Secrets and variables → Actions*). Trigger them from the Actions tab, or:

```bash
gh workflow run deploy.yml -f version="2.0.0"
gh workflow run rollback.yml -f reason="Testing rollback procedure"
```

## Test Results

See [`docs/test-results.md`](docs/test-results.md) for captured output.

## Strategy Comparison

| Strategy | Downtime | Rollback speed | Infra cost | Blast radius of a bad release |
|---|---|---|---|---|
| In-place overwrite | Seconds of mixed content | Slow — must re-upload old build | 1× | 100% of users, immediately |
| **Blue/green** | **None** | **Instant — flip the pointer** | **2×** | **0% if the health check catches it** |
| Canary | None | Fast — reset the weight | 2× | Only the canary slice (AWS caps CloudFront at 15%) |
| Rolling | None | Slow — must roll forward or re-deploy | ~1× | Grows as the rollout progresses |

Blue/green is the right fit here: the workload is a small static site where doubling
storage cost is negligible, and the original problem was precisely the mixed-content
window that in-place overwrite creates.

## Key Learnings

- **The atomic unit is the pointer, not the files.** Deploying and releasing become two
  separate actions, and only the second one is risky.
- **Health-check placement is the design.** Checking after the switch would make it a
  detection mechanism; checking before makes it a prevention mechanism.
- **State in Git beats state in a console.** `deployment.json` gives a reviewable audit
  trail of who switched what, when, and why — a CloudWatch dashboard cannot.
- **Rollback is free because the old environment was never touched.** The cost of that
  guarantee is running 2× the infrastructure permanently.
- **Manual dispatch is a feature.** Blue/green separates "code is merged" from "traffic
  moves", so a human decides when the second one happens.
- **Bucket naming is global.** Any lab that hardcodes a bucket prefix will collide the
  moment two people run it.

## Cleanup

Completed — all 8 resources destroyed after the lifecycle test.

```bash
aws s3 rm s3://deploy-lab-draian123-blue  --recursive
aws s3 rm s3://deploy-lab-draian123-green --recursive
terraform destroy -auto-approve
```

Buckets must be emptied first — Terraform cannot delete a non-empty bucket. Deleting the
objects is what forced the two-step: `terraform destroy` alone fails with
`BucketNotEmpty`.

## Submission

1. `git add` → `git commit` → `git push` to your fork
2. Open a Pull Request from your fork to the original lab repo
3. Paste the PR URL into the **Lab Submission** field in the Student Portal
