# Common Mistakes When Adding Load Balancer to ECS Service

## Summary of Issues Encountered

This document outlines the common mistakes made when trying to add an Application Load Balancer to an existing ECS Fargate service.

---

## ❌ Mistake 1: Wrong Target Type in Target Group

### The Problem
Created a target group with **target type "Instances"** instead of **"IP addresses"**.

### Why It Failed
- ECS Fargate uses `awsvpc` network mode
- In `awsvpc` mode, each task gets its own network interface and IP address
- Target groups must use **"IP addresses"** target type, not "Instances"
- The console showed the target group as greyed out with error: *"The target group is incompatible with the selected task definition's network mode which is set to awsvpc. Target type is instance but must be ip."*

### The Fix
Create a new target group with:
- **Target type**: `IP addresses` (not "Instances")
- Same VPC as your ECS service
- Protocol: HTTP, Port: 80

---

## ❌ Mistake 2: Missing Load Balancer Listener

### The Problem
Created the Application Load Balancer but forgot to create a **listener** on port 80.

### Why It Failed
- Load balancers need listeners to accept traffic
- Without a listener, the load balancer exists but doesn't route traffic
- When trying to update the ECS service, got error: *"The target group does not have an associated load balancer"*

### The Fix
After creating the load balancer, you must:
1. Create a listener on port 80 (or 443 for HTTPS)
2. Configure the listener to forward traffic to your target group
3. Only then can you attach the target group to the ECS service

---

## ❌ Mistake 3: Target Group Not Attached to Load Balancer

### The Problem
Created both the load balancer and target group separately, but didn't connect them via a listener.

### Why It Failed
- Target groups must be associated with a load balancer through a listener
- ECS service requires the target group to already be attached to a load balancer
- The error message was misleading - it said the target group doesn't have a load balancer, but really the listener was missing

### The Fix
Create the listener that connects the load balancer to the target group:
- Listener protocol: HTTP
- Listener port: 80
- Default action: Forward to target group

---

## ❌ Mistake 4: VPC Mismatch

### The Problem
Created target group in a different VPC than the ECS service.

### Why It Failed
- All resources must be in the same VPC:
  - Load balancer
  - Target group
  - ECS service subnets
- If VPCs don't match, resources can't communicate

### The Fix
Always verify:
- Load balancer VPC = Target group VPC = ECS service VPC
- Use the same VPC for all resources

---

## ❌ Mistake 5: Wrong Health Check Path

### The Problem
Set health check path to `/` when the application only responds on `/goals`.

### Why It Failed
- Health checks fail if the path doesn't return 200 OK
- Unhealthy targets are removed from the load balancer
- Application appears down even though it's running

### The Fix
Set health check path to match your application:
- If your app responds on `/goals`, use `/goals`
- If your app responds on `/`, use `/`
- Verify the path returns HTTP 200

---

## ❌ Mistake 6: Security Group Configuration

### The Problem
Security group for ECS tasks allows traffic from "Anywhere" (0.0.0.0/0) instead of from the load balancer.

### Why It's a Problem
- Security risk: exposes tasks directly to the internet
- Best practice: only allow traffic from the load balancer security group
- Tasks should not be directly accessible

### The Fix
Update ECS task security group:
- Remove rule allowing 0.0.0.0/0 on port 80
- Add rule allowing traffic from load balancer security group
- Source: Select the ALB security group (`goals-alb-sg`)

---

## ✅ Correct Order of Operations

To avoid these mistakes, follow this order:

1. **Create Target Group** (with IP target type)
2. **Create Load Balancer** (in same VPC)
3. **Create Listener** (attach target group to load balancer)
4. **Update ECS Service** (configure load balancer)
5. **Update Security Groups** (restrict access)

---

## 🔍 How to Verify Everything is Correct

### Check Target Group
```bash
aws elbv2 describe-target-groups \
  --target-group-names goals-app-targets-ip \
  --region eu-central-1 \
  --query 'TargetGroups[0].TargetType'
# Should return: "ip"
```

### Check Load Balancer Has Listener
```bash
aws elbv2 describe-listeners \
  --load-balancer-arn <ALB_ARN> \
  --region eu-central-1 \
  --query 'Listeners'
# Should return at least one listener
```

### Check ECS Service Has Load Balancer
```bash
aws ecs describe-services \
  --cluster goals-cluster \
  --services goals-app \
  --region eu-central-1 \
  --query 'services[0].loadBalancers'
# Should return array with target group ARN
```

### Check Target Health
```bash
aws elbv2 describe-target-health \
  --target-group-arn <TG_ARN> \
  --region eu-central-1
# Should show registered targets with "healthy" status
```

---

## 📝 Key Takeaways

1. **Target Type**: Always use "IP addresses" for Fargate/awsvpc
2. **Listener Required**: Load balancer needs a listener to route traffic
3. **Order Matters**: Create resources in the correct sequence
4. **VPC Consistency**: All resources must be in the same VPC
5. **Health Checks**: Use correct path that your app responds to
6. **Security**: Restrict task security groups to ALB traffic only

---

## ❌ Mistake 7: Backend App Not Listening When MongoDB Auth Fails

### The Problem
Backend application only starts listening on port 80 **after** MongoDB connection succeeds. If MongoDB authentication fails, the app never listens, causing load balancer health checks to fail.

### Why It Failed
- Backend code structure: `app.listen(80)` is called inside MongoDB connection callback
- If MongoDB connection fails → `app.listen(80)` never called → nothing listening on port 80
- Load balancer health checks hit port 80 → connection refused → target marked unhealthy
- MongoDB health check doesn't authenticate (just pings), so MongoDB shows HEALTHY even if user doesn't exist yet
- Backend tries to authenticate → fails → never starts listening

### The Fix

**Option 1: Start listening immediately (Recommended)**
Modify backend to start listening even if MongoDB isn't connected:
```javascript
// Start listening immediately
app.listen(80);

// Try to connect to MongoDB (retry in background)
mongoose.connect(connectionString, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}, (err) => {
  if (err) {
    console.error('FAILED TO CONNECT TO MONGODB');
    console.error(err);
    // Retry connection in background
  } else {
    console.log('CONNECTED TO MONGODB!!');
  }
});
```

**Option 2: Add health check endpoint**
Add a simple endpoint that doesn't require MongoDB:
```javascript
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});
```
Then use `/health` as health check path instead of `/goals`.

**Option 3: Increase health check grace period**
Give backend more time to connect to MongoDB:
- Set ECS service `healthCheckGracePeriodSeconds` to 120+ seconds
- This gives MongoDB time to fully initialize user

**Option 4: Fix MongoDB user creation timing**
- Increase MongoDB health check `startPeriod` to 60 seconds
- Ensures user is created before backend tries to connect

### Symptoms
- Backend logs show: "FAILED TO CONNECT TO MONGODB" with "AuthenticationFailed"
- Load balancer health checks fail immediately
- Targets show as "unhealthy" or "draining"
- ECS service events show: "Task failed ELB health checks"

---

**Date**: November 19, 2025  
**Issue**: Target group greyed out, service couldn't attach to load balancer  
**Root Cause**: Missing listener connecting load balancer to target group

**Additional Issue**: Backend not listening when MongoDB auth fails  
**Root Cause**: Backend only starts listening after MongoDB connection succeeds

