# Lab M5.06 - Deployment Strategies

**Cloud Engineering Bootcamp - Week 5, Day 3**  
**Module:** Cloud Automation & CI/CD

## 📋 Lab Overview

Implement different deployment strategies including blue/green, canary, and rolling deployments to achieve zero-downtime releases.

## 🎯 Learning Objectives

- Implement blue/green deployment strategy
- Configure canary deployments with traffic splitting
- Set up rolling update deployments
- Implement automated rollback procedures
- Monitor deployment health and metrics

## 📁 Repository Structure

```
ce-lab-deployment-strategies/
├── .github/
│   └── workflows/
│       ├── blue-green-deploy.yml
│       ├── canary-deploy.yml
│       └── rolling-deploy.yml
├── terraform/
│   ├── blue-green/
│   ├── canary/
│   └── rolling/
├── README.md
└── .gitignore
```

## ✅ Submission Requirements

1. **Deployment Workflows**
   - Blue/green deployment automation
   - Canary deployment with gradual rollout
   - Rolling update implementation

2. **Infrastructure Code**
   - Load balancer configuration
   - Target group management
   - Health check configuration

3. **Rollback Procedures**
   - Automated rollback on failure
   - Manual rollback capability

4. **Documentation**
   - Strategy comparison
   - Deployment process documentation

## 🎓 Grading Rubric

| Criteria | Points |
|----------|--------|
| **Blue/Green Deployment** | 30 |
| **Canary Deployment** | 30 |
| **Rolling Updates** | 25 |
| **Documentation** | 15 |
| **Total** | 100 |

## 💡 Tips

- Test deployments with a simple application first
- Implement health checks before deployment
- Use CloudWatch metrics for monitoring
- Practice rollback procedures

## 📚 Resources

- [AWS Deployment Strategies](https://docs.aws.amazon.com/whitepapers/latest/overview-deployment-options/deployment-strategies.html)
- [GitHub Deployments API](https://docs.github.com/en/rest/deployments)

## 🚀 Submission

Submit your repository URL through the course platform.
