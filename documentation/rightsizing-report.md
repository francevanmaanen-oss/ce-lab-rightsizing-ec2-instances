# EC2 Rightsizing Report

## Analysis Details
- **Date:** 2026-06-03
- **Duration:** 30 minutes of monitoring
- **Method:** CloudWatch metrics + synthetic load testing

## Instance Analysis

| Instance       | Type     | Avg CPU % | Avg Mem % | Recommendation        |
|----------------|----------|-----------|-----------|-----------------------|
| web-server     | t3.micro | 100%      | 33%       | Properly sized — keep |
| api-server     | t3.micro | 0.6%      | 24%       | Over-provisioned      |
| data-processor | t3.micro | 0.7%      | 24%       | Over-provisioned      |

## Simulated Production Savings

| Instance       | Simulated Current | Recommended | Monthly Saving |
|----------------|-------------------|-------------|----------------|
| web-server     | t3.medium         | t3.medium   | $0.00          |
| api-server     | t3.large          | t3.small    | $26.28         |
| data-processor | m5.xlarge         | t3.medium   | $107.31        |

**Total projected monthly saving: $133.59 (48% reduction)**

## Key Findings
1. **web-server:** CPU at 100% during load — properly sized for its workload.
2. **api-server:** CPU averaging 0.6% — severely over-provisioned.
3. **data-processor:** CPU averaging 0.7% — severely over-provisioned.