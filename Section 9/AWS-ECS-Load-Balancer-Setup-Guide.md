# Complete Guide: Adding Application Load Balancer to ECS Fargate Service

Complete step-by-step guide to add an Application Load Balancer (ALB) to your existing ECS Fargate service, providing a stable DNS URL instead of changing IP addresses.

**Prerequisites**: You have an existing ECS Fargate service running (e.g., `goals-app` service in `goals-cluster`)

---

## 🎯 Overview

This guide covers:
1. Creating a target group with correct configuration
2. Creating an Application Load Balancer
3. Creating a listener to connect them
4. Updating your ECS service to use the load balancer
5. Configuring security groups properly
6. Testing and verification

**Expected Result**: Stable URL like `http://goals-app-alb-1234567890.eu-central-1.elb.amazonaws.com/goals`

---

## Part 1: Create Target Group (GUI Method)

### Step 1: Navigate to EC2 Console

1. Go to AWS Console: https://console.aws.amazon.com/
2. Search for "EC2" in the top search bar
3. Click on **EC2**
4. Select your region: **eu-central-1 (Frankfurt)** (or your region)

### Step 2: Create Target Group

1. In the left sidebar, scroll down to **"Load Balancing"**
2. Click **"Target Groups"**
3. Click **"Create target group"** (orange button)

### Step 3: Configure Target Group

#### Basic Configuration

**⚠️ CRITICAL**: Choose the correct target type!

- **Choose a target type**: Select **"IP addresses"** (NOT "Instances"!)
  - This is required for Fargate/awsvpc network mode
  - If you select "Instances", it won't work with Fargate

- **Target group name**: `goals-app-targets-ip`
- **Protocol**: `HTTP`
- **Port**: `80`
- **VPC**: Select the **same VPC** as your ECS service
  - Usually your default VPC
  - You can find your service's VPC in ECS → Service → Networking tab

#### Health Checks

- **Health check protocol**: `HTTP`
- **Health check path**: `/goals` (or `/` if your app responds there)
  - This should match an endpoint your backend responds to
- **Advanced health check settings** (click to expand):
  - **Healthy threshold**: `2`
  - **Unhealthy threshold**: `2`
  - **Timeout**: `5` seconds
  - **Interval**: `30` seconds
  - **Success codes**: `200`

#### Register Targets

- **Skip this step** - ECS will automatically register tasks when they start

### Step 4: Create Target Group

1. Review all settings
2. Click **"Create target group"** at the bottom

✅ **Target group created!**

---

## Part 2: Create Application Load Balancer (GUI Method)

### Step 1: Navigate to Load Balancers

1. In EC2 Console, left sidebar → **"Load Balancing"** → **"Load Balancers"**
2. Click **"Create Load Balancer"** (orange button)

### Step 2: Select Load Balancer Type

- Select **"Application Load Balancer"** (first option)
- Click **"Create"**

### Step 3: Configure Load Balancer

#### Basic Configuration

- **Name**: `goals-app-alb`
- **Scheme**: **Internet-facing** (to access from internet)
- **IP address type**: `IPv4`

#### Network Mapping

- **VPC**: Select the **same VPC** as your target group and ECS service
- **Availability Zones**: 
  - Select **at least 2 subnets** in different availability zones
  - These should be **public subnets** (with internet gateway)
  - You can use the same subnets your ECS service uses

#### Security Groups

Click **"Create new security group"**:

- **Security group name**: `goals-alb-sg`
- **Description**: `Security group for goals app load balancer`
- **Inbound rules**: Add rule:
  - **Type**: `HTTP`
  - **Port**: `80`
  - **Source**: `Anywhere-IPv4` (0.0.0.0/0)
  - **Description**: `Allow HTTP from internet`
- **Outbound rules**: Leave default (all traffic)
- Click **"Create security group"**
- Select the newly created security group

#### Listeners and Routing

**⚠️ IMPORTANT**: You have two options here:

**Option A: Create listener now (recommended)**
- **Protocol**: `HTTP`
- **Port**: `80`
- **Default action**: Select your target group `goals-app-targets-ip` from dropdown
- If target group doesn't appear, you can create it later (see Part 3)

**Option B: Create listener later**
- Leave default action as "None" for now
- We'll create the listener in Part 3

### Step 4: Review and Create

1. Review all settings
2. Click **"Create load balancer"** at the bottom
3. Wait 2-3 minutes for the load balancer to become **active**

✅ **Load balancer created!**

---

## Part 3: Create Listener (If Not Created in Part 2)

**⚠️ CRITICAL STEP**: This is often missed! The load balancer needs a listener to route traffic.

### Step 1: Navigate to Listeners

1. Go to EC2 Console → **Load Balancers**
2. Click on your load balancer: `goals-app-alb`
3. Click on the **"Listeners"** tab

### Step 2: Add Listener

1. Click **"Add listener"** button
2. Configure:
   - **Protocol**: `HTTP`
   - **Port**: `80`
   - **Default action**: 
     - **Type**: `Forward to`
     - **Target group**: Select `goals-app-targets-ip`
3. Click **"Add"**

✅ **Listener created!** The load balancer can now route traffic to your target group.

---

## Part 4: Update ECS Service to Use Load Balancer

### Step 1: Navigate to Your ECS Service

1. Go to ECS Console: https://console.aws.amazon.com/ecs/
2. Click **"Clusters"** → **"goals-cluster"**
3. Click on the **"Services"** tab
4. Click on your service: **"goals-app"** (or your service name)

### Step 2: Update Service

1. Click **"Update"** button (top right)

### Step 3: Configure Load Balancing

Scroll down to **"Load balancing"** section:

#### Load Balancer Configuration

- **Load balancer type**: Select **"Application Load Balancer"**

- **Load balancer name**: Select `goals-app-alb` from dropdown

- **Container to load balance**:
  - **Container name**: Select `backend` (or your backend container name)
  - **Production listener port**: `80`
  - **Production listener protocol**: `HTTP`

- **Target group name**: Select `goals-app-targets-ip` from dropdown
  - ⚠️ If it's greyed out, see troubleshooting section below

- **Health check grace period**: `60` seconds
  - Gives containers time to start before health checks begin

### Step 4: Review and Update

1. Scroll through and review all settings
2. Click **"Update"** at the bottom
3. Wait 2-3 minutes for the service to update

✅ **Service updated!** Tasks will now register with the load balancer automatically.

---

## Part 5: Configure Security Groups

### Step 1: Update ECS Task Security Group

1. Go to EC2 Console → **Security Groups**
2. Find your ECS task security group (e.g., `goals-app-sg`)
3. Click on it, then click **"Edit inbound rules"**

#### Update Inbound Rules

**Remove** (if exists):
- Rule allowing `0.0.0.0/0` on port 80

**Add**:
- **Type**: `Custom TCP`
- **Port**: `80`
- **Source**: 
  - Select **"Security group"** from dropdown
  - Choose `goals-alb-sg` (your load balancer security group)
- **Description**: `Allow traffic from ALB`

4. Click **"Save rules"**

✅ **Security updated!** Tasks are now only accessible through the load balancer.

---

## Part 6: Get Your Stable URL

### Step 1: Find Load Balancer DNS Name

1. Go to EC2 Console → **Load Balancers**
2. Click on `goals-app-alb`
3. In the **"Description"** tab, find **"DNS name"**
4. Copy this DNS name (e.g., `goals-app-alb-512855108.eu-central-1.elb.amazonaws.com`)

### Step 2: Your Application URL

Your application is now accessible at:

```
http://YOUR-ALB-DNS-NAME/goals
```

Example:
```
http://goals-app-alb-512855108.eu-central-1.elb.amazonaws.com/goals
```

**This URL is stable and won't change**, even if tasks restart or IPs change!

---

## Part 7: Verify Everything Works

### Step 1: Check Target Health

1. Go to EC2 Console → **Target Groups**
2. Click on `goals-app-targets-ip`
3. Click on **"Health checks"** tab
4. Wait 2-3 minutes for targets to register
5. Check that targets show **"healthy"** status

### Step 2: Test Your Application

#### Using curl:
```bash
curl http://YOUR-ALB-DNS-NAME/goals
```

Expected response:
```json
{"goals":[]}
```

#### Using Browser:
Simply open: `http://YOUR-ALB-DNS-NAME/goals` in your browser

### Step 3: Check ECS Service

1. Go to ECS Console → Your service
2. Click **"Tasks"** tab
3. Verify tasks are **RUNNING**
4. Click on a task to see details
5. Verify containers are **HEALTHY**

---

## Part 8: CLI Method (Alternative)

If you prefer using AWS CLI, here are the commands:

### 1. Create Target Group
```bash
aws elbv2 create-target-group \
  --name goals-app-targets-ip \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-03b0a582f4a03d775 \
  --target-type ip \
  --health-check-path /goals \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 2 \
  --region eu-central-1
```

### 2. Create Load Balancer
```bash
aws elbv2 create-load-balancer \
  --name goals-app-alb \
  --subnets subnet-038bbc9e73dc7833f subnet-015b801597f0c0fab \
  --security-groups sg-0dea82ef629714619 \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4 \
  --region eu-central-1
```

### 3. Create Listener
```bash
# Get ARNs
LB_ARN=$(aws elbv2 describe-load-balancers \
  --names goals-app-alb \
  --region eu-central-1 \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

TG_ARN=$(aws elbv2 describe-target-groups \
  --names goals-app-targets-ip \
  --region eu-central-1 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Create listener
aws elbv2 create-listener \
  --load-balancer-arn $LB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN \
  --region eu-central-1
```

### 4. Update ECS Service
```bash
TG_ARN=$(aws elbv2 describe-target-groups \
  --names goals-app-targets-ip \
  --region eu-central-1 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

aws ecs update-service \
  --cluster goals-cluster \
  --service goals-app \
  --load-balancers targetGroupArn=$TG_ARN,containerName=backend,containerPort=80 \
  --region eu-central-1
```

---

## 🔧 Troubleshooting

### Issue 1: Target Group Greyed Out in ECS Service Update

**Symptoms**: Target group appears in dropdown but is greyed out with error about network mode.

**Causes**:
- Target group has wrong target type ("Instances" instead of "IP addresses")
- Target group is in different VPC than service
- Target group is not attached to a load balancer via listener

**Solutions**:
1. Verify target type is "IP addresses":
   ```bash
   aws elbv2 describe-target-groups \
     --target-group-names goals-app-targets-ip \
     --region eu-central-1 \
     --query 'TargetGroups[0].TargetType'
   # Should return: "ip"
   ```

2. Verify VPC matches:
   ```bash
   # Check target group VPC
   aws elbv2 describe-target-groups \
     --target-group-names goals-app-targets-ip \
     --region eu-central-1 \
     --query 'TargetGroups[0].VpcId'
   
   # Check service VPC (from subnets)
   aws ec2 describe-subnets \
     --subnet-ids <your-subnet-ids> \
     --region eu-central-1 \
     --query 'Subnets[0].VpcId'
   ```

3. Verify listener exists:
   ```bash
   aws elbv2 describe-listeners \
     --load-balancer-arn <ALB_ARN> \
     --region eu-central-1 \
     --query 'Listeners'
   # Should return at least one listener
   ```

### Issue 2: Targets Not Registering

**Symptoms**: Target group shows no targets or targets are unhealthy.

**Causes**:
- Tasks not running
- Health check path incorrect
- Security groups blocking traffic
- Tasks still starting (wait 2-3 minutes)

**Solutions**:
1. Check tasks are running:
   ```bash
   aws ecs list-tasks \
     --cluster goals-cluster \
     --service-name goals-app \
     --region eu-central-1
   ```

2. Verify health check path:
   - Test: `curl http://TASK_IP/goals` (should return 200)
   - Update target group health check path if needed

3. Check security groups:
   - ALB security group should allow inbound on port 80
   - Task security group should allow inbound from ALB security group

4. Wait 2-3 minutes for registration (automatic)

### Issue 3: 502 Bad Gateway

**Symptoms**: Load balancer returns 502 error.

**Causes**:
- No healthy targets in target group
- Tasks not running
- Health checks failing

**Solutions**:
1. Check target health:
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn <TG_ARN> \
     --region eu-central-1
   ```

2. Check CloudWatch logs for application errors
3. Verify health check path is correct
4. Check tasks are running and containers are healthy

### Issue 4: Connection Timeout

**Symptoms**: Can't connect to load balancer DNS name.

**Causes**:
- Load balancer not active
- Security group blocking traffic
- DNS not propagated (wait a few minutes)

**Solutions**:
1. Verify load balancer state is "active"
2. Check ALB security group allows inbound on port 80
3. Wait 5-10 minutes for DNS propagation

---

## 📊 Architecture Diagram

```
Internet
   │
   ▼
[Application Load Balancer]
   │ (Listener: HTTP:80)
   ▼
[Target Group (IP type)]
   │
   ▼
[ECS Fargate Tasks]
   ├── backend (port 80)
   └── mongodb (port 27017)
```

---

## 💰 Cost Information

**Additional costs for ALB**:
- **ALB base cost**: ~€16-20/month
- **LCU (Load Balancer Capacity Units)**: ~€1-2/month for light traffic
- **Total additional**: ~€17-22/month

The stable DNS name is included at no extra cost.

---

## ✅ Verification Checklist

After completing all steps, verify:

- [ ] Target group created with "IP addresses" target type
- [ ] Target group in same VPC as ECS service
- [ ] Load balancer created and active
- [ ] Listener created on port 80
- [ ] Listener forwards to target group
- [ ] ECS service updated with load balancer configuration
- [ ] Security groups configured correctly
- [ ] Targets registered and healthy in target group
- [ ] Application accessible via ALB DNS name
- [ ] Health checks passing

---

## 🎯 Summary

**What You've Accomplished**:
- ✅ Created Application Load Balancer with stable DNS
- ✅ Configured target group for Fargate (IP target type)
- ✅ Connected load balancer to target group via listener
- ✅ Updated ECS service to use load balancer
- ✅ Secured traffic flow (tasks only accessible via ALB)
- ✅ Application now has stable URL that won't change

**Key Learnings**:
1. **Target Type Matters**: Fargate requires "IP addresses", not "Instances"
2. **Listener Required**: Load balancer needs listener to route traffic
3. **Order Matters**: Create target group → load balancer → listener → update service
4. **VPC Consistency**: All resources must be in same VPC
5. **Security**: Restrict task access to ALB only

---

## 📚 Additional Resources

- **AWS ECS Documentation**: https://docs.aws.amazon.com/ecs/
- **Application Load Balancer Guide**: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/
- **Target Groups for ECS**: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html
- **Fargate Networking**: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html

---

**Created**: November 19, 2025  
**Last Updated**: November 19, 2025  
**Region**: eu-central-1 (Frankfurt)  
**Application**: Goals App (MongoDB + Node.js Backend)

---

🎉 **Congratulations! Your application now has a stable URL!** 🎉

