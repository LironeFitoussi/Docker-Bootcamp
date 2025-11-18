# AWS ECS Deployment Guide - GUI Step-by-Step

Complete guide to deploy MongoDB + Node.js Backend to AWS ECS Fargate using the AWS Console.

**Application**: Goals App (MongoDB + Node.js)  
**Deployment Method**: AWS ECS Fargate (Serverless Containers)  
**Region**: eu-central-1 (Frankfurt) - or your preferred region

---

## 📋 Prerequisites

- ✅ AWS Account with console access
- ✅ Backend image pushed to Docker Hub: `lironefitoussi111/goals-node`
- ✅ MongoDB will use official image: `mongo:latest`

---

## 🎯 Architecture Overview

Your deployment will use:
- **AWS ECS Fargate**: Serverless container orchestration
- **Two containers in one task**: MongoDB + Backend (share localhost network)
- **Health Checks**: Ensures MongoDB fully initializes before backend connects
- **CloudWatch Logs**: For monitoring and debugging

---

## Part 1: Create ECS Cluster

### Step 1: Navigate to ECS Console

1. Sign in to AWS Console: https://console.aws.amazon.com/
2. Go to **ECS** (search for "ECS" in the top search bar)
3. Select your region: **eu-central-1 (Frankfurt)** (or your preferred region)

### Step 2: Create Cluster

1. Click **"Clusters"** in the left sidebar
2. Click **"Create cluster"** (orange button)
3. Fill in the details:
   - **Cluster name**: `goals-cluster`
   - **Infrastructure**: Select **AWS Fargate (serverless)**
   - Leave other settings as default
4. Click **"Create"** at the bottom

✅ **Cluster created!**

---

## Part 2: Create CloudWatch Log Group

Before creating the task definition, set up logging:

### Step 1: Navigate to CloudWatch

1. Open a new tab: https://console.aws.amazon.com/cloudwatch/
2. Click **"Logs"** → **"Log groups"** in the left sidebar

### Step 2: Create Log Group

1. Click **"Create log group"** (orange button)
2. **Log group name**: `/ecs/goals-app`
3. Leave retention settings as default (or set to 1 week to save costs)
4. Click **"Create"**

✅ **Log group created!**

---

## Part 3: Create Task Definition

This is the most important part! The task definition includes BOTH containers with proper timing configuration.

### Step 1: Start Creating Task Definition

1. Go back to **ECS Console**
2. Click **"Task Definitions"** in the left sidebar
3. Click **"Create new task definition"** (dropdown) → **"Create new task definition"**

### Step 2: Configure Task Definition

**Basic Configuration:**
- **Task definition family**: `goals-app`
- **Launch type**: Select **AWS Fargate**

**Infrastructure requirements:**
- **Operating system/Architecture**: `Linux/X86_64`
- **CPU**: `0.5 vCPU` (512)
- **Memory**: `1 GB` (1024)
- **Task role**: Leave as **None**
- **Task execution role**: Select **ecsTaskExecutionRole**
  - If it doesn't exist, click "Create new role" and AWS will create it

### Step 3: Add Container 1 - MongoDB

Click **"Add container"** button

#### Container Details:
- **Name**: `mongodb`
- **Image URI**: `mongo:latest`
- **Essential container**: ✅ **YES** (check this box!)

#### Port Mappings:
Click **"Add more port mappings"** if needed:
- **Container port**: `27017`
- **Protocol**: `TCP`
- **Port name**: `mongodb-27017-tcp` (auto-filled)
- **App protocol**: Leave empty

#### Environment Variables:
Click **"Add environment variable"** twice to add these:

1. First variable:
   - **Key**: `MONGO_INITDB_ROOT_USERNAME`
   - **Value**: `lirone`

2. Second variable:
   - **Key**: `MONGO_INITDB_ROOT_PASSWORD`
   - **Value**: `secret`

#### Health Check (CRITICAL!):
Scroll down to **"Health check"** section and expand it:

- **Command**: 
  ```
  CMD-SHELL,mongosh --eval 'db.runCommand({ping: 1})' --quiet || exit 1
  ```
- **Interval**: `10` seconds
- **Timeout**: `5` seconds
- **Start period**: `40` seconds (gives MongoDB time to initialize!)
- **Retries**: `3`

> 💡 **Why 40 seconds?** MongoDB needs 30-60 seconds to fully initialize and create the admin user. The start period gives it this time.

#### Log Configuration:
Scroll to **"Log collection"**:
- Check ✅ **"Use log collection"**
- **Log driver**: `awslogs` (should be default)
- **awslogs-group**: `/ecs/goals-app`
- **awslogs-region**: `eu-central-1` (or your region)
- **awslogs-stream-prefix**: `mongodb`

Click **"Add"** at the bottom (this saves the container, doesn't create the task yet)

### Step 4: Add Container 2 - Backend

Click **"Add container"** again

#### Container Details:
- **Name**: `backend`
- **Image URI**: `lironefitoussi111/goals-node`
- **Essential container**: ✅ **YES**

#### Port Mappings:
- **Container port**: `80`
- **Protocol**: `TCP`
- **Port name**: `backend-80-tcp`
- **App protocol**: Leave empty

#### Environment Variables:
Click **"Add environment variable"** three times:

1. **Key**: `MONGODB_USERNAME`, **Value**: `lirone`
2. **Key**: `MONGODB_PASSWORD`, **Value**: `secret`
3. **Key**: `MONGODB_URL`, **Value**: `localhost`

> ⚠️ **Important**: Use `localhost` (not `mongodb`)! Both containers share the same network namespace in Fargate.

#### Startup Dependency Ordering (CRITICAL!):
Scroll down to **"Startup dependency ordering"** section:

Click **"Add"**:
- **Container name**: Select `mongodb` from dropdown
- **Condition**: Select **HEALTHY** (NOT "START"!)

> 💡 **This is the key fix!** Backend waits for MongoDB to pass health checks before starting.

#### Log Configuration:
- Check ✅ **"Use log collection"**
- **awslogs-group**: `/ecs/goals-app`
- **awslogs-region**: `eu-central-1` (or your region)
- **awslogs-stream-prefix**: `backend`

Click **"Add"** at the bottom

### Step 5: Review and Create

1. **Review** all settings - you should see 2 containers: `mongodb` and `backend`
2. Scroll down to **Storage** section - leave as default (no volumes needed for testing)
3. Click **"Create"** (orange button at the very bottom)

✅ **Task definition created!**

---

## Part 4: Create and Run the Service

Now let's deploy your application!

### Step 1: Navigate to Your Cluster

1. Click **"Clusters"** in the left sidebar
2. Click on **"goals-cluster"**

### Step 2: Create Service

1. In the **"Services"** tab, click **"Create"**

### Step 3: Configure Service

#### Environment:
- **Compute options**: Select **Launch type**
- **Launch type**: **FARGATE**

#### Deployment Configuration:
- **Application type**: **Service**
- **Task definition**:
  - **Family**: `goals-app`
  - **Revision**: `1 (LATEST)` or select the latest revision
- **Service name**: `goals-app-service`
- **Desired tasks**: `1`

#### Deployment Options:
Leave defaults (rolling deployment is fine)

### Step 4: Configure Networking (CRITICAL!)

#### VPC and Subnets:
- **VPC**: Select your **default VPC** (or any VPC you have)
- **Subnets**: Select **at least 2 subnets** in different availability zones
  - ✅ Check at least 2 subnet boxes
  - Make sure they are **public subnets** (with internet gateway access)

#### Security Group:
Click **"Create a new security group"**:
- **Security group name**: `goals-app-sg`
- **Description**: `Security group for goals application`
- **Inbound rules**:
  - Should have one rule by default
  - Make sure there's a rule for:
    - **Type**: `HTTP` or `Custom TCP`
    - **Port**: `80`
    - **Source**: `Anywhere-IPv4` (0.0.0.0/0)
    - **Description**: `Allow HTTP access`

#### Public IP (CRITICAL!):
- **Public IP**: ✅ **ENABLED** (Turn this ON!)
  - This is essential to access your app from the internet

### Step 5: Load Balancing (Optional - Skip for Testing)

- **Load balancer type**: Select **"None"**
- You can add an Application Load Balancer later for production

### Step 6: Service Auto Scaling (Optional - Skip for Testing)

- Leave **"Do not adjust the service's desired count"** selected

### Step 7: Review and Create

1. Review all settings
2. Click **"Create"** (orange button at bottom)

✅ **Service is deploying!**

---

## Part 5: Monitor Deployment

### Step 1: Wait for Deployment

The deployment takes 3-5 minutes. Watch the progress:

1. Stay on your service page: **goals-cluster** → **goals-app-service**
2. Click the **"Tasks"** tab
3. Watch the task status change:
   - `PROVISIONING` → Downloading images
   - `PENDING` → Starting containers
   - `RUNNING` → Containers are running!

### Step 2: Check Container Health

1. Click on the **task ID** (the long alphanumeric string)
2. Scroll down to **"Containers"** section
3. Check both containers:
   - **mongodb**: Should show "HEALTHY" status (after ~40 seconds)
   - **backend**: Should show "RUNNING" status

> 💡 If MongoDB stays "UNHEALTHY", check CloudWatch logs (see troubleshooting section)

---

## Part 6: Get Your Application URL

### Step 1: Find the Task

1. In your service, go to **"Tasks"** tab
2. Click on the running **task ID**

### Step 2: Get Public IP

1. Scroll down to **"Configuration"** section
2. Look for **"Public IP"** under networking details
3. **Copy this IP address** (e.g., `63.181.9.68`)

### Step 3: Access Your Application

Open your browser or terminal and access:

```
http://YOUR_PUBLIC_IP/goals
```

Example:
```
http://63.181.9.68/goals
```

You should see: `{"goals":[]}`

---

## Part 7: Test Your API

### Using curl (Terminal):

```bash
# Get all goals
curl http://YOUR_PUBLIC_IP/goals

# Add a new goal
curl -X POST http://YOUR_PUBLIC_IP/goals \
  -H "Content-Type: application/json" \
  -d '{"text":"Deployed to AWS!"}'

# Get goals again to see your new goal
curl http://YOUR_PUBLIC_IP/goals

# Delete a goal (replace GOAL_ID with actual ID from response)
curl -X DELETE http://YOUR_PUBLIC_IP/goals/GOAL_ID
```

### Using Browser:

Simply open: `http://YOUR_PUBLIC_IP/goals` in your browser

---

## Part 8: View Logs

### Step 1: Navigate to CloudWatch

1. Go to CloudWatch Console: https://console.aws.amazon.com/cloudwatch/
2. Click **"Logs"** → **"Log groups"** → `/ecs/goals-app`

### Step 2: View Container Logs

You'll see log streams named:
- `mongodb/mongodb/TASK_ID` - MongoDB logs
- `backend/backend/TASK_ID` - Backend logs

Click on a stream to view logs.

### Step 3: Look for Success Message

In the backend logs, you should see:
```
CONNECTED TO MONGODB!!
```

This confirms the connection was successful!

---

## 🔧 Troubleshooting

### Issue 1: Task Keeps Stopping

**Check logs in CloudWatch:**
1. Go to `/ecs/goals-app` log group
2. Look at backend logs for errors
3. Look at mongodb logs for initialization issues

**Common causes:**
- MongoDB health check failing (increase start period to 60 seconds)
- Backend trying to connect before MongoDB is ready (verify dependency is set to "HEALTHY")
- Network connectivity issues

### Issue 2: Cannot Access the Application

**Check these items:**
1. **Security Group**: Verify port 80 is allowed from 0.0.0.0/0
   - Go to EC2 → Security Groups → `goals-app-sg`
   - Check "Inbound rules" tab
2. **Public IP**: Verify "Auto-assign public IP" is ENABLED
   - Go to your service → "Networking" section
3. **Task Status**: Make sure task is RUNNING
   - Go to service → "Tasks" tab

### Issue 3: MongoDB Health Check Failing

**Symptoms**: MongoDB container shows "UNHEALTHY" status

**Solutions**:
1. Increase health check **start period** to 60 seconds
2. Check MongoDB logs for startup errors
3. Verify the health check command is correct:
   ```
   CMD-SHELL,mongosh --eval 'db.runCommand({ping: 1})' --quiet || exit 1
   ```

### Issue 4: Authentication Failed

**Symptoms**: Backend logs show "Authentication failed" or "UserNotFound"

**This means**: Backend started before MongoDB finished creating the user

**Solution**: 
- Verify backend dependency is set to **HEALTHY** (not START)
- Increase MongoDB health check start period to 60 seconds
- Create a new task definition revision and update the service

### Issue 5: Connection Timeout

**Symptoms**: Backend logs show "connection timeout" or "ECONNREFUSED"

**Solutions**:
1. Verify `MONGODB_URL=localhost` in backend environment variables
2. Both containers must be in the same task (don't create separate tasks)
3. Check that both containers are in "RUNNING" status

---

## 🔄 Update Your Application

When you make changes to your backend code:

### Step 1: Build and Push New Image

```bash
# Build new version
docker build -t lironefitoussi111/goals-node:latest .

# Push to Docker Hub
docker push lironefitoussi111/goals-node:latest
```

### Step 2: Force New Deployment

1. Go to your service: **goals-cluster** → **goals-app-service**
2. Click **"Update service"**
3. Don't change anything, just scroll down
4. Check ✅ **"Force new deployment"**
5. Click **"Update"**

The service will pull the latest image and restart with your changes!

---

## 💰 Cost Information

**Running 24/7**:
- Fargate: ~€30/month (0.5 vCPU, 1 GB memory)
- Data transfer: ~€1-2/month (minimal for testing)
- **Total**: ~€31-32/month

**Save Money**:

### Stop the Service (when not using):
1. Go to your service → **"Update service"**
2. Set **"Desired tasks"** to `0`
3. Click **"Update"**
4. No charges while stopped!

### Start Again:
1. Update service
2. Set **"Desired tasks"** to `1`
3. Wait 2-3 minutes for startup

---

## 🗑️ Complete Cleanup (Delete Everything)

To avoid ongoing charges:

### Step 1: Delete Service
1. Go to **Clusters** → **goals-cluster** → **goals-app-service**
2. First: **Update service** → Set **"Desired tasks"** to `0` → **Update**
3. Wait for tasks to stop (30 seconds)
4. Click **"Delete service"** (top right)
5. Type `delete` to confirm

### Step 2: Delete Cluster
1. Go to **Clusters**
2. Select **goals-cluster** checkbox
3. Click **"Delete cluster"**
4. Confirm deletion

### Step 3: Delete Task Definitions
1. Go to **Task Definitions**
2. Select **goals-app** family
3. Select all revisions
4. **Actions** → **Deregister**
5. Confirm

### Step 4: Delete CloudWatch Log Group
1. Go to **CloudWatch** → **Logs** → **Log groups**
2. Select `/ecs/goals-app`
3. Click **"Actions"** → **"Delete log group(s)"**
4. Confirm

### Step 5: Delete Security Group (Optional)
1. Go to **EC2** → **Security Groups**
2. Find `goals-app-sg`
3. **Actions** → **Delete security group**
4. Confirm

✅ **All resources deleted - no more charges!**

---

## ⚠️ Important Notes

### Data Persistence

**Current Setup**: Data is NOT persistent!
- If the task restarts, all MongoDB data is LOST
- This is fine for testing and development

**For Production**, use one of these:
1. **AWS DocumentDB** (MongoDB-compatible, fully managed)
2. **MongoDB Atlas** (Official MongoDB cloud service)
3. **Amazon EFS** (Elastic File System) for persistent storage
4. **Amazon EBS volumes** (only works with EC2 launch type, not Fargate)

### Security Considerations

**Current Setup**: Basic security suitable for testing

**For Production**, improve security:
1. **Use AWS Secrets Manager** for passwords (don't use plain text env vars)
2. **Use Application Load Balancer** with HTTPS
3. **Use private subnets** with NAT Gateway
4. **Restrict security group** to specific IP ranges
5. **Enable Container Insights** for monitoring
6. **Set up CloudWatch Alarms** for failures

### Scaling

**Current Setup**: 1 task (single instance)

**To Scale**:
1. Update service
2. Increase **"Desired tasks"** to 2, 3, etc.
3. Add Application Load Balancer to distribute traffic
4. Consider using auto-scaling policies

---

## 📚 Key Learnings

### Why Health Checks Are Critical

The main challenge with this deployment is **timing**:

1. **Without health check**: Backend starts as soon as MongoDB container is "running"
   - MongoDB is still initializing (creating users)
   - Backend tries to authenticate → fails with "UserNotFound"

2. **With health check**: Backend waits until MongoDB is "healthy"
   - MongoDB fully initializes (30-40 seconds)
   - User is created and ready
   - Backend connects successfully! ✅

### Container Dependencies

```json
"dependsOn": [
    {
        "containerName": "mongodb",
        "condition": "HEALTHY"  // ← Use HEALTHY, not START!
    }
]
```

This simple configuration change is what makes the whole deployment work!

---

## 🎯 Summary

**What You Deployed**:
- ✅ MongoDB container with authentication
- ✅ Node.js backend container
- ✅ Both running in same Fargate task (serverless)
- ✅ Health checks ensuring proper initialization
- ✅ CloudWatch logs for monitoring
- ✅ Public IP for internet access

**Architecture Decisions**:
- **Fargate**: No server management needed
- **Single Task**: Both containers share localhost network
- **Health Checks**: Ensures MongoDB ready before backend connects
- **Public IP**: Direct internet access (simple for testing)

**Next Steps for Production**:
- Add Application Load Balancer
- Use managed database (DocumentDB or Atlas)
- Implement proper secrets management
- Set up monitoring and alarms
- Configure auto-scaling

---

## 📞 Support Resources

- **AWS ECS Documentation**: https://docs.aws.amazon.com/ecs/
- **AWS Fargate Guide**: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html
- **Container Health Checks**: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#container_definition_healthcheck
- **CloudWatch Logs**: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/

---

**Created**: November 18, 2025  
**Last Updated**: November 18, 2025  
**Deployment Region**: eu-central-1 (Frankfurt)  
**Application**: Goals App (MongoDB + Node.js Backend)

---

🎉 **Congratulations on deploying your application to AWS!** 🎉

