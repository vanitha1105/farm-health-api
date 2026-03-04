pipeline {

    // Use Docker agent to run the pipeline inside a Docker container
    agent {
        docker {
            image 'docker:24.0' // Docker CLI image used for build & push operations
        }
    }

    // Global environment variables available to all stages
    environment {
        IMAGE = "flox/farm-health-api"          // Docker image name
        VERSION = "0.1.0"                      // Image version tag
        DOCKERHUB_CREDENTIALS = "dockerhub-creds"   // Jenkins credential ID for DockerHub
        SLACK_WEBHOOK = "slack-webhook"              // Jenkins secret text ID for Slack webhook
        APP_URL = "http://flox.ai"  // Production service URL for health check
    }

    // Add timestamps to Jenkins console output (helps debugging)
    options {
        timestamps()
    }

    stages {

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    # Build image with version tag and latest tag
                    docker build -t $IMAGE:$VERSION -t $IMAGE:latest .
                '''
            }
        }

        stage('Test Container Health') {
            steps {
                sh '''
                    echo "Starting test container..."
                    # Run container in background and expose port 8000
                    docker run -d --rm --name test -p 8000:8000 $IMAGE:$VERSION

                    # Give container time to start
                    sleep 5

                    echo "Running health check..."
                    # Run custom health check script against local container
                    ./healthcheck.sh --retries 5 http://localhost:8000

                    # Stop container (ignore error if already stopped)
                    docker stop test || true
                '''
            }
        }

        // -----------------------------
        // Push Image to DockerHub
        // Only runs on main branch
        // -----------------------------
        stage('Push to DockerHub') {
            when { branch 'main' }  // Prevent pushing from feature branches
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "$DOCKERHUB_CREDENTIALS",
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        # Login securely using password from Jenkins credentials
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                        # Push versioned and latest tags
                        docker push $IMAGE:$VERSION
                        docker push $IMAGE:latest
                    '''
                }
            }
        }

        // -----------------------------
        // Deploy to Kubernetes
        // Only runs on main branch
        // -----------------------------
        stage('Deploy to Kubernetes') {
            when { branch 'main' }
            steps {
                sh '''
                    echo "Deploying to Kubernetes..."
                    # Apply Kubernetes manifests
                    kubectl apply -f k8s/

                    echo "Waiting for rollout..."
                    # Wait for deployment to finish rolling update
                    kubectl rollout status deployment/farm-health-api --timeout=60s
                '''
            }
        }

        // -----------------------------
        // Post-Deployment Health Check
        // -----------------------------
        stage('Post-Deploy Health Check') {
            when { branch 'main' }
            steps {
                withCredentials([string(credentialsId: "$SLACK_WEBHOOK", variable: 'WEBHOOK')]) {
                    sh '''
                        echo "Waiting for service to stabilize..."
                        # Allow time for service/ingress to become reachable
                        sleep 15

                        # Run health check against production URL
                        # Sends Slack alert automatically if unhealthy
                        ./healthcheck.sh --retries 5 --webhook $WEBHOOK $APP_URL
                    '''
                }
            }
        }
    }

    // -----------------------------
    // Post Actions (Always Executed)
    // -----------------------------
    post {

        success {
            echo "Pipeline completed successfully."
        }

        failure {
            echo "Pipeline failed."

            // Send Slack notification on failure
            withCredentials([string(credentialsId: "$SLACK_WEBHOOK", variable: 'WEBHOOK')]) {
                sh '''
                    curl -s -X POST -H "Content-Type: application/json" \
                    --data '{"text":"❌ FLOX Pipeline Failed!"}' \
                    $WEBHOOK > /dev/null
                '''
            }
        }

        always {
            // Cleanup unused Docker resources to free disk space
            sh 'docker system prune -f || true'
        }
    }
}