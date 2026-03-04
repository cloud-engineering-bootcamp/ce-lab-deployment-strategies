
# Lab M5.06 - Deployment Strategies (Blue/Green)
 
## Architecture
 
Two S3 static website buckets serve as deployment targets:
- **Blue** — `deploy-lab-blue.s3-website-us-east-1.amazonaws.com`
- **Green** — `deploy-lab-green.s3-website-us-east-1.amazonaws.com`
 
Only one is "active" at a time, tracked by `deployment.json`.


Start Here: Fork, Clone, and Submit

Fork the lab repository to your GitHub account.

Clone your fork locally:

git clone https://github.com/MaryaAhmadi/ce-lab-infrastructure-testing.git
cd ce-lab-infrastructure-testing

Complete the lab instructions, saving all work (files, screenshots, notes) in this repository.

Stage, commit, and push your changes:

git add .
git commit -m "Complete lab M5.05"
git push origin main

Open a Pull Request (PR) from your fork to the original lab repository.

Copy the PR URL and submit it in the Lab Submission field on the Student Portal.

## 📋 Lab Overview

This lab focuses on implementing comprehensive testing for infrastructure code, including:

Syntax validation

Linting

Security scanning

Compliance and custom checks

You will build a multi-layer testing strategy for Terraform code to ensure consistency, security, and compliance.

## 🎯 Learning Objectives

By the end of this lab, you will be able to:

Implement infrastructure testing frameworks

Configure automated validation in CI/CD pipelines

Run Terraform validation (terraform validate) and linting (tflint)

Perform security scanning using Checkov

Create and run custom validation tests for naming conventions, tagging, and plan verification

## 📁 Repository Structure
ce-lab-infrastructure-testing/
├── .github/
│   └── workflows/
│       └── test-infrastructure.yml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── scripts/
│   ├── validate-conventions.sh
│   ├── validate-plan.sh
│   └── install-hooks.sh
├── tests/
│   ├── terraform_test.go
│   └── compliance_test.sh
├── .tflint.hcl
├── .pre-commit-config.yaml
├── README.md
└── .gitignore

## Architecture

The deployment uses two S3 static website buckets as targets:

Blue — http://deploy-lab-maryam-ironhack-blue.s3-website-us-east-1.amazonaws.com

Green — http://deploy-lab-maryam-ironhack-green.s3-website-us-east-1.amazonaws.com

At any time, only one environment is active, tracked via deployment.json.



                ┌───────────────┐
                │  GitHub Repo  │
                └───────┬───────┘
                        │ push / workflow_dispatch
                        ▼
                ┌────────────────┐
                │ GitHub Actions │
                │  Workflows     │
                └───────┬────────┘
         ┌───────────────┴───────────────┐
         ▼                               ▼
   ┌─────────────┐                 ┌─────────────┐
   │  S3 Blue    │                 │  S3 Green   │
   │ Website     │                 │ Website     │
   └─────────────┘                 └─────────────┘
         ▲                               ▲
         │           Health Check        │
         └───────────────┬───────────────┘
                         ▼
                  deployment.json
          (tracks active environment, version, history)



## WorkflowsDeploy (.github/workflows/deploy.yml)

Detect inactive environment (blue or green) from deployment.json.

Deploy new content to the inactive bucket.

Health-check the deployment (HTTP 200).

Switch active_environment in deployment.json.

Commit and push the updated state to GitHub.

Rollback (.github/workflows/rollback.yml)

Detect currently active environment from deployment.json.

Switch back to the previous environment (no redeployment needed).

Record rollback reason in deployment.json history.

Commit and push the updated state.

Deployment State (deployment.json)

Tracks:

active_environment: currently active environment (blue or green)

last_deployed: timestamp

deployed_by: username or GitHub actor

version: deployed version

history: full audit trail of deployments and rollbacks

Example:

{
  "active_environment": "blue",
  "last_deployed": "2026-02-26T10:00:00Z",
  "deployed_by": "initial-setup",
  "version": "1.0.0",
  "history": [
    {
      "environment": "blue",
      "version": "1.0.0",
      "timestamp": "2026-02-26T10:00:00Z",
      "action": "initial-deploy"
    }
  ]
}
Usage
Trigger Deployment
gh workflow run deploy.yml -f version="2.0.0"
gh run watch
Trigger Rollback
gh workflow run rollback.yml -f reason="Testing rollback"
gh run watch
Verify Active Environment
cat deployment.json
./check_deploy.sh
Key Learnings

Blue/green deployment ensures zero downtime.

Inactive environment is always ready for next deploy.

Rollback is instant — just switch the pointer.

Deployment history provides an audit trail.

GitHub Actions automates deployment and rollback.

Notes / Tips

Always add .terraform/ to .gitignore to avoid committing large provider files.

Ensure AWS credentials are stored as GitHub Secrets: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY.

Test deployment and rollback locally with check_deploy.sh.

Use semantic versioning (version="2.0.0") in workflow inputs.


## ✅ Submission Requirements

Complete the lab as described and save your work in this repository:

Testing Workflows

Terraform validation

TFLint configuration and execution

Security scanning with Checkov

Custom compliance tests

Infrastructure Code

Working Terraform configuration

Proper resource configuration

Test Documentation

Testing strategy explanation

Test coverage documentation
