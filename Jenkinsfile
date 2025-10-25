pipeline {
    agent any

    environment {
        PROJECT_ID = "vigilant-list-476000-n7"
        REGION = "us-central1"
        REPO_NAME = "studentsurvey-repo"
        IMAGE_NAME = "studentsurvey"
        CLUSTER_NAME = "my-cluster2"
        GCP_CREDENTIALS = credentials('gcp-key')
    }

    stages {
        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:latest .
                '''
            }
        }

        stage('Authenticate with GCP') {
            steps {
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
                sh '''
                docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME/$IMAGE_NAME:latest
                '''
            }
        }

        stage('Deploy to GKE') {
            steps {
                withCredentials([file(credentialsId: 'gcp-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                    sh '''
                    gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                    gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION
                    kubectl apply -f deployment.yaml
                    kubectl apply -f service.yaml
                    kubectl apply -f autoscaler.yaml
                    '''
                }
            }
        }
    }
}
