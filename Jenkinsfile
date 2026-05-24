pipeline {
    agent any
    
    // Automatically clean workspace before build
    options {
        // Keep only last 5 builds to save disk space
        buildDiscarder(logRotator(numToKeepStr: '5'))
        // Timeout builds after 30 minutes
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Pre-Build Cleanup') {
            steps {
                script {
                    echo '🧹 Cleaning up before build...'
                    // Remove dangling images and containers
                    sh 'docker system prune -f || true'
                    // Show current disk usage
                    sh 'df -h | grep -E "Filesystem|/dev/root"'
                    sh 'docker system df'
                }
            }
        }
        
        stage('Clone Repository') {
            steps {
                echo '📥 Cloning repository...'
                git branch: 'main', url: 'https://github.com/GaniBaig/two-tier-flask.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo '🔨 Building Flask application image...'
                    // Build with no-cache to ensure clean build
                    sh 'docker build -t flask-app:latest .'
                    
                    // Tag with build number for tracking
                    sh "docker tag flask-app:latest flask-app:build-${BUILD_NUMBER}"
                }
            }
        }
        
        stage('Remove Old Images') {
            steps {
                script {
                    echo '🗑️ Removing old Flask images...'
                    // Keep only last 2 builds, remove older ones
                    sh '''
                        # Get all flask-app images except latest and current build
                        OLD_IMAGES=$(docker images flask-app --format "{{.Tag}}" | grep "build-" | sort -rn | tail -n +3)
                        
                        # Remove old images if any exist
                        if [ ! -z "$OLD_IMAGES" ]; then
                            for tag in $OLD_IMAGES; do
                                echo "Removing flask-app:$tag"
                                docker rmi flask-app:$tag || true
                            done
                        fi
                    '''
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                script {
                    echo '🚀 Deploying application with Docker Compose...'
                    // Stop existing containers
                    sh 'docker compose down || true'
                    
                    // Start application
                    sh 'docker compose up -d --build'
                    
                    // Wait for services to be healthy
                    echo '⏳ Waiting for services to be healthy...'
                    sh 'sleep 10'
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                script {
                    echo '✅ Verifying deployment...'
                    // Check if containers are running
                    sh 'docker compose ps'
                    
                    // Test health endpoint
                    sh '''
                        for i in {1..30}; do
                            if curl -f http://localhost:5001/health; then
                                echo "✅ Application is healthy!"
                                exit 0
                            fi
                            echo "Waiting for application... ($i/30)"
                            sleep 2
                        done
                        echo "❌ Application health check failed"
                        exit 1
                    '''
                }
            }
        }
        
        stage('Post-Deploy Cleanup') {
            steps {
                script {
                    echo '🧹 Final cleanup...'
                    // Remove dangling images created during build
                    sh 'docker image prune -f'
                    
                    // Show final disk usage
                    echo '📊 Final disk usage:'
                    sh 'df -h | grep -E "Filesystem|/dev/root"'
                    sh 'docker system df'
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo '📊 Build Summary'
                sh 'docker ps -a'
                sh 'docker images | head -10'
            }
        }
        
        success {
            echo '✅ Pipeline completed successfully!'
        }
        
        failure {
            script {
                echo '❌ Pipeline failed! Running emergency cleanup...'
                // Emergency cleanup on failure
                sh 'docker system prune -f || true'
                sh 'docker volume prune -f || true'
            }
        }
        
        cleanup {
            // Clean workspace after build
            cleanWs()
        }
    }
}