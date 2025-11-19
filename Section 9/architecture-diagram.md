# AWS ECS Architecture Diagram

Complete architecture diagram for the Goals App deployment on AWS ECS Fargate with Application Load Balancer and EFS.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              INTERNET                                       │
│                         (Users & Clients)                                   │
└──────────────────────────────┬──────────────────────────────────────────────┘
                                │
                                │ HTTP (Port 80)
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    APPLICATION LOAD BALANCER (ALB)                          │
│                    Name: goals-app-alb                                      │
│                    DNS: goals-app-alb-512855108.eu-central-1.elb.amazonaws.com│
│                    Scheme: Internet-facing                                   │
│                    Type: Application Load Balancer                           │
│                    Security Group: sg-057d945b5e72c9767                      │
│                                                                              │
│                    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│                    │  Listener    │  │  Listener   │  │  Listener   │       │
│                    │  HTTP:80     │  │  (Future)   │  │  (Future)   │       │
│                    └──────┬───────┘  └─────────────┘  └─────────────┘       │
└───────────────────────────┼──────────────────────────────────────────────────┘
                            │
                            │ Routes to Target Group
                            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TARGET GROUP                                         │
│                    Name: goals-app-targets-ip                               │
│                    Type: IP addresses (for Fargate)                          │
│                    Protocol: HTTP                                           │
│                    Port: 80                                                  │
│                    Health Check: /goals (HTTP 200)                          │
│                    Health Check Interval: 30s                               │
│                    Healthy Threshold: 2                                     │
│                    Unhealthy Threshold: 5                                   │
└───────────────────────────┬──────────────────────────────────────────────────┘
                            │
                            │ Registers ECS Tasks
                            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         VPC: vpc-03b0a582f4a03d775                          │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    AVAILABILITY ZONE: eu-central-1a                   │  │
│  │  Subnet: subnet-015b801597f0c0fab (Public)                            │  │
│  │                                                                        │  │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │  │
│  │  │              ECS TASK (Fargate)                                   │ │  │
│  │  │              Task Definition: goals-app:7                        │ │  │
│  │  │              CPU: 0.5 vCPU | Memory: 1 GB                        │ │  │
│  │  │              Network Mode: awsvpc                                 │ │  │
│  │  │              Public IP: ENABLED                                   │ │  │
│  │  │              Security Groups: Multiple                            │ │  │
│  │  │                                                                   │ │  │
│  │  │  ┌────────────────────────┐  ┌────────────────────────┐          │ │  │
│  │  │  │   Container: backend   │  │  Container: mongodb   │          │ │  │
│  │  │  │   Image: goals-node    │  │  Image: mongo:latest  │          │ │  │
│  │  │  │   Port: 80             │  │  Port: 27017          │          │ │  │
│  │  │  │                        │  │                       │          │ │  │
│  │  │  │   Health Check:        │  │  Health Check:        │          │ │  │
│  │  │  │   - Path: /goals      │  │  - Command: mongosh   │          │ │  │
│  │  │  │   - Interval: 30s     │  │  - Interval: 10s      │          │ │  │
│  │  │  │                       │  │  - Start Period: 40s  │          │ │  │
│  │  │  │   Depends On:         │  │                       │          │ │  │
│  │  │  │   mongodb (HEALTHY)   │  │                       │          │ │  │
│  │  │  └───────────┬───────────┘  └───────────┬───────────┘          │ │  │
│  │  │              │                           │                      │ │  │
│  │  │              │  localhost:27017          │                      │ │  │
│  │  │              └───────────┬───────────────┘                      │ │  │
│  │  │                          │                                      │ │  │
│  │  │                          │ Mount Point                          │ │  │
│  │  │                          │ /data/db                             │ │  │
│  │  │                          ▼                                      │ │  │
│  │  │              ┌───────────────────────────┐                      │ │  │
│  │  │              │   EFS Volume: data        │                      │ │  │
│  │  │              │   (Persistent Storage)    │                      │ │  │
│  │  │              └───────────────────────────┘                      │ │  │
│  │  └──────────────────────────────────────────────────────────────────┘ │  │
│  │                                                                        │  │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │  │
│  │  │              EFS MOUNT TARGET                                      │ │  │
│  │  │              Mount Target ID: fsmt-0baea88f09f8a68da              │ │  │
│  │  │              IP: 172.31.25.248                                    │ │  │
│  │  │              State: available                                      │ │  │
│  │  └──────────────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    AVAILABILITY ZONE: eu-central-1b                   │  │
│  │  Subnet: subnet-0840ebb18df82ff96 (Public)                            │  │
│  │                                                                        │  │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │  │
│  │  │              EFS MOUNT TARGET                                      │ │  │
│  │  │              Mount Target ID: fsmt-099d48bae60be75a2              │ │  │
│  │  │              IP: 172.31.39.91                                      │ │  │
│  │  │              State: available                                      │ │  │
│  │  └──────────────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐  │
│  │                    AVAILABILITY ZONE: eu-central-1c                   │  │
│  │  Subnet: subnet-038bbc9e73dc7833f (Public)                            │  │
│  │                                                                        │  │
│  │  ┌──────────────────────────────────────────────────────────────────┐ │  │
│  │  │              EFS MOUNT TARGET                                      │ │  │
│  │  │              Mount Target ID: fsmt-0a8820928fb7c597a              │ │  │
│  │  │              IP: 172.31.14.54                                      │ │  │
│  │  │              State: available                                      │ │  │
│  │  └──────────────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────┬──────────────────────────────────────────────────┘
                            │
                            │ NFS Protocol (Port 2049)
                            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    ELASTIC FILE SYSTEM (EFS)                                │
│                    File System ID: fs-0a5f51e8e8e20b6d4                    │
│                    Name: db-storage                                         │
│                    Performance Mode: generalPurpose                         │
│                    Throughput Mode: elastic                                 │
│                    Encrypted: Yes (KMS)                                     │
│                    Lifecycle State: available                               │
│                    Mount Targets: 3 (one per AZ)                            │
│                                                                              │
│                    ┌──────────────────────────────────────┐                │
│                    │   Persistent MongoDB Data Storage     │                │
│                    │   - Database files                    │                │
│                    │   - Shared across all tasks          │                │
│                    │   - Survives task restarts           │                │
│                    └──────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                         CLOUDWATCH LOGS                                     │
│                    Log Group: /ecs/goals-app                                │
│                                                                              │
│                    ┌──────────────────┐  ┌──────────────────┐               │
│                    │  mongodb logs    │  │  backend logs    │               │
│                    │  Stream prefix:  │  │  Stream prefix:  │               │
│                    │  mongodb         │  │  backend         │               │
│                    └──────────────────┘  └──────────────────┘               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Mermaid Diagram (Interactive)

```mermaid
graph TB
    Internet[Internet<br/>Users & Clients]
    
    ALB[Application Load Balancer<br/>goals-app-alb<br/>Internet-facing<br/>DNS: goals-app-alb-512855108...]
    
    TG[Target Group<br/>goals-app-targets-ip<br/>Type: IP addresses<br/>Health Check: /goals]
    
    subgraph VPC["VPC: vpc-03b0a582f4a03d775"]
        subgraph AZ1["Availability Zone: eu-central-1a<br/>Subnet: subnet-015b801597f0c0fab"]
            Task1[ECS Task - Fargate<br/>goals-app:7<br/>CPU: 0.5 vCPU | Memory: 1 GB]
            
            subgraph Containers1["Containers"]
                Backend1[Backend Container<br/>Image: goals-node<br/>Port: 80<br/>Health: /goals]
                Mongo1[MongoDB Container<br/>Image: mongo:latest<br/>Port: 27017<br/>Health: mongosh ping]
            end
            
            EFSMount1[EFS Mount Target<br/>IP: 172.31.25.248<br/>State: available]
        end
        
        subgraph AZ2["Availability Zone: eu-central-1b<br/>Subnet: subnet-0840ebb18df82ff96"]
            EFSMount2[EFS Mount Target<br/>IP: 172.31.39.91<br/>State: available]
        end
        
        subgraph AZ3["Availability Zone: eu-central-1c<br/>Subnet: subnet-038bbc9e73dc7833f"]
            EFSMount3[EFS Mount Target<br/>IP: 172.31.14.54<br/>State: available]
        end
    end
    
    EFS[Elastic File System<br/>fs-0a5f51e8e8e20b6d4<br/>Name: db-storage<br/>Encrypted: Yes<br/>Performance: generalPurpose]
    
    CloudWatch[CloudWatch Logs<br/>Log Group: /ecs/goals-app<br/>Streams: mongodb, backend]
    
    Internet -->|HTTP:80| ALB
    ALB -->|Routes| TG
    TG -->|Registers| Task1
    Task1 --> Containers1
    Backend1 -.->|localhost:27017| Mongo1
    Mongo1 -->|Mount /data/db| EFSMount1
    EFSMount1 -->|NFS| EFS
    EFSMount2 -->|NFS| EFS
    EFSMount3 -->|NFS| EFS
    Containers1 -->|Logs| CloudWatch
    
    style Internet fill:#e1f5ff
    style ALB fill:#ffd700
    style TG fill:#90ee90
    style Task1 fill:#87ceeb
    style Backend1 fill:#98fb98
    style Mongo1 fill:#ffb6c1
    style EFS fill:#dda0dd
    style CloudWatch fill:#f0e68c
```

---

## Component Details

### 1. Application Load Balancer (ALB)
- **Name**: `goals-app-alb`
- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **DNS**: `goals-app-alb-512855108.eu-central-1.elb.amazonaws.com`
- **Availability Zones**: 3 (eu-central-1a, 1b, 1c)
- **Security Group**: `sg-057d945b5e72c9767`
- **Listeners**: HTTP:80 → Target Group

### 2. Target Group
- **Name**: `goals-app-targets-ip`
- **Type**: IP addresses (required for Fargate)
- **Protocol**: HTTP
- **Port**: 80
- **Health Check**:
  - Path: `/goals`
  - Protocol: HTTP
  - Interval: 30 seconds
  - Timeout: 10 seconds
  - Healthy threshold: 2
  - Unhealthy threshold: 5
  - Success codes: 200

### 3. ECS Cluster & Service
- **Cluster**: `goals-cluster`
- **Service**: `goals-app`
- **Launch Type**: Fargate (serverless)
- **Desired Count**: 1
- **Task Definition**: `goals-app:7`
- **Network Mode**: `awsvpc`
- **Public IP**: Enabled

### 4. ECS Task
- **CPU**: 0.5 vCPU (512)
- **Memory**: 1 GB (1024)
- **Containers**: 2 (backend + mongodb)
- **Subnets**: 3 subnets across 3 AZs
- **Security Groups**: Multiple (ALB access, EFS access)

### 5. Containers

#### Backend Container
- **Name**: `backend`
- **Image**: `lironefitoussi111/goals-node`
- **Port**: 80
- **Health Check**: HTTP GET `/goals` (via ALB target group)
- **Dependency**: Waits for `mongodb` container to be HEALTHY
- **Environment Variables**:
  - `MONGODB_URL=localhost`
  - `MONGODB_USERNAME=lirone`
  - `MONGODB_PASSWORD=secret`

#### MongoDB Container
- **Name**: `mongodb`
- **Image**: `mongo:latest`
- **Port**: 27017 (internal only, not exposed externally)
- **Health Check**:
  - Command: `mongosh --eval 'db.runCommand({ping: 1})' --quiet || exit 1`
  - Interval: 10 seconds
  - Timeout: 5 seconds
  - Start period: 40 seconds (allows MongoDB initialization)
  - Retries: 3
- **Environment Variables**:
  - `MONGO_INITDB_ROOT_USERNAME=lirone`
  - `MONGO_INITDB_ROOT_PASSWORD=secret`
- **Volume Mount**: `/data/db` → EFS volume `data`

### 6. Elastic File System (EFS)
- **File System ID**: `fs-0a5f51e8e8e20b6d4`
- **Name**: `db-storage`
- **Performance Mode**: generalPurpose
- **Throughput Mode**: elastic
- **Encryption**: Enabled (KMS)
- **Mount Targets**: 3 (one per availability zone)
  - AZ 1a: `172.31.25.248`
  - AZ 1b: `172.31.39.91`
  - AZ 1c: `172.31.14.54`
- **Purpose**: Persistent storage for MongoDB data directory

### 7. CloudWatch Logs
- **Log Group**: `/ecs/goals-app`
- **Stream Prefixes**:
  - `mongodb` - MongoDB container logs
  - `backend` - Backend container logs
- **Region**: eu-central-1

---

## Data Flow

1. **User Request**:
   - User accesses `http://goals-app-alb-512855108.eu-central-1.elb.amazonaws.com/goals`
   - DNS resolves to ALB IP addresses

2. **Load Balancer**:
   - ALB receives request on HTTP:80
   - Listener routes to target group `goals-app-targets-ip`
   - ALB performs health check on targets

3. **Target Group**:
   - Routes request to healthy ECS task IP address
   - Health check: HTTP GET `/goals` every 30 seconds

4. **ECS Task**:
   - Request reaches backend container on port 80
   - Backend processes request

5. **Database Access**:
   - Backend connects to MongoDB via `localhost:27017`
   - MongoDB reads/writes data to `/data/db`
   - Data is stored on EFS (persistent storage)

6. **Response**:
   - Backend sends response back through ALB
   - ALB returns response to user

---

## Security Groups

### ALB Security Group (`sg-057d945b5e72c9767`)
- **Inbound**: HTTP (port 80) from `0.0.0.0/0` (Internet)
- **Outbound**: All traffic

### ECS Task Security Groups
- **Inbound**: 
  - HTTP (port 80) from ALB security group
  - NFS (port 2049) from EFS mount targets
- **Outbound**: All traffic

---

## High Availability Features

1. **Multi-AZ Deployment**:
   - ALB spans 3 availability zones
   - ECS tasks can run in any of 3 subnets
   - EFS has mount targets in all 3 AZs

2. **Health Checks**:
   - ALB target group health checks ensure only healthy tasks receive traffic
   - Container health checks ensure proper startup order

3. **Persistent Storage**:
   - EFS provides shared, persistent storage
   - Data survives task restarts
   - Accessible from all availability zones

4. **Auto-Scaling Ready**:
   - Service can scale tasks based on demand
   - EFS supports concurrent access from multiple tasks

---

## Network Architecture

```
Internet Gateway
       │
       ▼
┌──────────────┐
│  Public      │  Subnet 1a (subnet-015b801597f0c0fab)
│  Subnet      │  Subnet 1b (subnet-0840ebb18df82ff96)
│              │  Subnet 1c (subnet-038bbc9e73dc7833f)
│  ┌────────┐  │
│  │  ALB   │  │
│  └───┬────┘  │
│      │       │
│  ┌───▼────┐  │
│  │  ECS   │  │
│  │ Tasks  │  │
│  └───┬────┘  │
│      │       │
│  ┌───▼────┐  │
│  │  EFS   │  │
│  │ Mount  │  │
│  │Targets │  │
│  └────────┘  │
└──────────────┘
```

---

## Key Architecture Decisions

1. **Fargate over EC2**: Serverless container hosting, no server management
2. **ALB over Classic LB**: Layer 7 routing, better for containerized apps
3. **EFS for MongoDB**: Persistent storage that survives task restarts
4. **Multi-container Task**: Both containers share localhost network (simpler connectivity)
5. **Health Check Dependencies**: Backend waits for MongoDB to be HEALTHY before starting
6. **Public Subnets**: Direct internet access (simpler for testing, consider private subnets + NAT for production)

---

## Scaling Considerations

- **Horizontal Scaling**: Increase `desiredCount` in ECS service
- **Auto Scaling**: Configure ECS service auto-scaling based on CPU/memory metrics
- **EFS**: Supports concurrent access from multiple tasks
- **ALB**: Automatically distributes traffic across healthy targets

---

**Last Updated**: Based on AWS resources scanned on November 19, 2025  
**Region**: eu-central-1 (Frankfurt)  
**Account**: 975050225319

