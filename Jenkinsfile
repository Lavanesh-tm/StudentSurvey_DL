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
