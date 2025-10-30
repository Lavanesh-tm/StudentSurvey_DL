# 🌐 SWE 645 – Student Survey Web Application (Cloud Deployment & CI/CD)

**Authors:** Dhanush Neelakantan (G01503107) & Lavanesh Mahendran (G01545858)  
**Course:** SWE 645 – Component Based Software Development  
**Assignment:** Homework 2 – Containerization + Kubernetes + Jenkins Pipeline  

---

## 📘 Overview

This project builds upon our Homework 1 **Student Survey web application** and transforms it into a fully containerized, cloud-native system with **automated CI/CD**.

We used:
- **Docker** for containerization  
- **Google Kubernetes Engine (GKE)** for scalable, managed deployment  
- **Jenkins** for automated integration and deployment from **GitHub**

The goal is to make the Student Survey website continuously deployable and resilient with at least **three pods running at all times** and **auto-scaling** based on resource usage.

---

## 🧩 Project Structure

```
SWE645-StudentSurvey/
│
├── index.html                    # Homepage with profile, animation, and survey link
├── survey.html                   # Student feedback form with validation
│
├── Dockerfile                    # Defines the Tomcat-based web app container
├── deployment.yaml               # Kubernetes deployment (3 replicas)
├── service.yaml                  # LoadBalancer service for external access
├── autoscaler.yaml               # Horizontal Pod Autoscaler (3–6 replicas)
│
├── Jenkinsfile                   # Jenkins pipeline for build + deploy
├── README.md                     # (this file)
│
└── assets/
    ├── happy-student-boy-with-books-isolated-free-photo.jpg
    ├── images.jpg
    └── pro.png
```

---

## 🧠 Application Description

The **Student Survey Web Application** allows users to:
- Fill in their basic details (name, address, email, survey date)
- Select what they liked most about the campus
- Indicate how they heard about the university
- Enter raffle data (validated numerically)
- Submit responses that simulate a backend submission process

The front-end uses **Bootstrap 5**, simple **JavaScript validation**, and **CSS animations**.

---

## 🐳 Step 1 – Docker Containerization

We first containerized the web app using **Docker**.

### Dockerfile
```dockerfile
# Use lightweight NGINX image
FROM nginx:latest

# Copy all files from the current directory to the NGINX web root
COPY . /usr/share/nginx/html

# Expose port 80 for web traffic
EXPOSE 80

# Start NGINX
CMD ["nginx", "-g", "daemon off;"]

```

### Commands Used
```bash
# Build Docker image
docker build -t dhanush853/studentsurvey:1.0 .

# Run locally for testing
docker run -d -p 8080:8080 dhanush853/studentsurvey:1.0

# Push to Docker Hub
docker login
docker push dhanush853/studentsurvey:1.0
```

---

## ☸️ Step 2 – Kubernetes Deployment on Google Kubernetes Engine (GKE)

We used **GKE** (instead of Rancher) to manage and orchestrate our containers.

### Steps Followed

1. **Enabled GKE API** on Google Cloud Console.  
2. **Created a cluster**:
   ```bash
   gcloud container clusters create studentsurvey-cluster \
   --num-nodes=3 \
   --machine-type=e2-medium \
   --region=us-east1
   ```
3. **Connected local environment**:
   ```bash
   gcloud container clusters get-credentials studentsurvey-cluster --region us-east1
   kubectl get nodes
   ```
4. **Deployed the app**:
   ```bash
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   ```
5. **Enabled auto-scaling**:
   ```bash
   kubectl apply -f autoscaler.yaml
   ```

---

### Deployment YAML
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: studentsurvey-deployment
  labels:
    app: studentsurvey
spec:
  replicas: 3
  selector:
    matchLabels:
      app: studentsurvey
  template:
    metadata:
      labels:
        app: studentsurvey
    spec:
      containers:
        - name: studentsurvey
          # ✅ Base image reference (Jenkins will override this tag each build)
          image: us-central1-docker.pkg.dev/vigilant-list-476000-n7/studentsurvey-repo/studentsurvey:latest
          
          # ✅ Always pull latest image from Artifact Registry
          imagePullPolicy: Always

          # ✅ Nginx serves on port 80
          ports:
            - containerPort: 80

          # ✅ Optional: lightweight readiness + liveness probes
          livenessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 30

          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10

```

###  Service YAML
```yaml
apiVersion: v1
kind: Service
metadata:
  name: studentsurvey-service
  labels:
    app: studentsurvey
spec:
  type: LoadBalancer
  selector:
    app: studentsurvey
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80

```

### Example Autoscaler YAML
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: studentsurvey-deployment
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: studentsurvey-deployment
  minReplicas: 3
  maxReplicas: 6
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60

```

---

### Verify Deployment
```bash
kubectl get pods
kubectl get svc
kubectl get hpa
```

Example output:
```
NAME                REFERENCE                     TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
studentsurvey-hpa   Deployment/studentsurvey      10%/70%         3         6         3          5m
```

✅ Confirms 3 pods always running and auto-scaling between 3–6.

End-point url : http://34.9.241.239/

---

## 🔁 Step 3 – Jenkins CI/CD Pipeline Integration

The **Jenkins pipeline** automates everything — from pulling new code on GitHub to redeploying it live on GKE.

### Jenkins Setup
1. Created a **Jenkins VM** on Google Compute Engine.  
2. Installed required packages:
   ```bash
   sudo apt update
   sudo apt install openjdk-17-jdk docker.io -y
   sudo snap install kubectl --classic
   ```
3. Added DockerHub credentials under Jenkins → Manage Credentials.  
4. Installed Jenkins plugins: Docker, Kubernetes CLI, GitHub Integration.  
5. Connected GitHub repository via webhook trigger.

---

### Jenkinsfile Pipeline
```groovy
pipeline {
    agent any

    environment {
        PROJECT_ID = "vigilant-list-476000-n7"
        REGION = "us-central1"
        REPO_NAME = "studentsurvey-repo"
        IMAGE_NAME = "studentsurvey"
        CLUSTER_NAME = "my-cluster2"
        IMAGE_TAG = "${BUILD_NUMBER}"   // ✅ unique tag for each build
    }

    stages {
        stage('Checkout Source') {
            steps {
                echo '📦 Cloning GitHub repository...'
                git branch: 'main', url: 'https://github.com/Lavanesh-tm/StudentSurvey_DL.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh '''
                    docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$IMAGE_TAG .
                '''
            }
        }

        stage('Authenticate with GCP') {
            steps {
                echo '🔐 Authenticating with Google Cloud...'
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        gcloud config set project $PROJECT_ID
                        gcloud auth configure-docker $REGION-docker.pkg.dev --quiet
                    '''
                }
            }
        }

        stage('Push Docker Image to Artifact Registry') {
            steps {
                echo '🚀 Pushing Docker image to Artifact Registry...'
                sh '''
                    docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$IMAGE_TAG
                '''
            }
        }

        stage('Deploy to GKE') {
            steps {
                echo '☸️ Deploying to GKE cluster...'
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID
                        
                        # Apply Kubernetes configuration files
                        kubectl apply -f service.yaml
                        kubectl apply -f autoscaler.yaml
                        
                        # ✅ Update the deployment image with the new build tag
                        kubectl set image deployment/studentsurvey-deployment studentsurvey=$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:$IMAGE_TAG --record
                        
                        # ✅ Wait for rollout to finish to ensure pods update properly
                        kubectl rollout status deployment/studentsurvey-deployment
                        
                        echo "✅ Deployment completed successfully!"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '🎉 Pipeline executed successfully! App deployed on GKE.'
        }
        failure {
            echo '❌ Pipeline failed. Check the stage logs above for errors.'
        }
    }
}

```

### Pipeline Workflow
1. **GitHub Commit → Jenkins Triggered**  
2. Jenkins **builds new Docker image**  
3. Jenkins **pushes image to Docker Hub**  
4. Jenkins **updates deployment on GKE**  
5. GKE **restarts pods with new version**  
6. Website auto-updates ✅

---

## 🚀 Step 4 – Testing and Scalability Verification

### Verify Scaling
```bash
kubectl get hpa
kubectl describe hpa studentsurvey-hpa
```

Observe pod scaling in:
```bash
kubectl get pods -w
```

✅ At least 3 pods always remain running — demonstrating resiliency and high availability.

Jenkins pipeline url: http://34.121.250.9:8080/job/deploy-pipeline/

---

## 🧩 Step 5 – Validation and Results

- Website accessible via **LoadBalancer External IP**
- Jenkins successfully re-deploys after every code commit
- Verified that pods automatically restart if terminated manually
- Auto-scaler adds pods under heavy load and removes idle pods when traffic is low

---

## 🔒 Security and Best Practices

- DockerHub credentials stored securely in Jenkins environment variables.  
- Used non-root Tomcat container for safety.  
- GKE handles node repair and pod restart automatically.  
- Service accounts limited to least privilege for cluster deployment.  

---

## 📸 Demonstration Recording Guide

For our assignment video, we demonstrated the following:
1. Docker build and push process  
2. Display GKE console showing 3 running pods  
3. Demonstrate Jenkins pipeline triggering on commit  
4. Open website via public LoadBalancer IP  
5. Show `kubectl get hpa` confirming scalability  

---

## 📚 References

- SWE 645 Assignment 2 – Official Guidelines  
- Installation & Setup Guide by Prof. Emile Issaelkhoury  
- [Docker Documentation](https://docs.docker.com/)  
- [Google Kubernetes Engine Docs](https://cloud.google.com/kubernetes-engine/docs)  
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/docker/)  

---

## ✅ Summary

This project successfully demonstrates:
- Continuous integration and deployment (GitHub → Jenkins → GKE)  
- Cloud-native scalability with **minimum 3 pods always running**  
- Auto-scaling and high availability via GKE HPA  
- Hands-on DevOps workflow from build to production

---

👥 Contributions
Contributor	Contribution Summary:
Dhanush Neelakantan (G01503107)	Worked on Docker containerization, Jenkins pipeline automation, and deployment integration with Google Kubernetes Engine (GKE).
Lavanesh Mahendran (G01545858)	Developed the front-end (index.html and survey.html), configured Kubernetes manifests (deployment, service, and autoscaler), and performed scalability and testing verification.

---

**Authors:**  
👨‍💻 *Dhanush Neelakantan*  
👨‍💻 *Lavanesh Mahendran*  
📅 *George Mason University – Fall 2025*
