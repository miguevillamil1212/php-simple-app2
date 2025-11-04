pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('docker-hub-credentials')
        IMAGE_NAME = "miguel1212/php-simple-app2"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/miguevillamil1212/php-simple-app2.git'
            }
        }

        stage('Generate Tag') {
            steps {
                script {
                    def GIT_COMMIT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    def DATE_TAG = sh(script: "date +%Y%m%d-%H%M%S", returnStdout: true).trim()
                    def VERSION_TAG = "${DATE_TAG}-${GIT_COMMIT}"
                    env.VERSION_TAG = VERSION_TAG
                    echo "Versión generada: ${VERSION_TAG}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    echo "=== Construyendo imagen ==="
                    docker build -t $IMAGE_NAME:$VERSION_TAG .
                    docker tag $IMAGE_NAME:$VERSION_TAG $IMAGE_NAME:latest
                """
            }
        }

        stage('Push to DockerHub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo "=== Subiendo imagen a DockerHub ==="
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $IMAGE_NAME:$VERSION_TAG
                        docker push $IMAGE_NAME:latest
                    """
                }
            }
        }
    }

    post {
        always {
            echo "=== Limpieza final ==="
            sh 'docker system prune -f || true'
        }
        success {
            echo "Pipeline completado con éxito"
            echo "Se subieron las siguientes versiones:"
            echo "→ $IMAGE_NAME:latest"
            echo "→ $IMAGE_NAME:$VERSION_TAG"
        }
        failure {
            echo "Pipeline falló"
        }
    }
}
