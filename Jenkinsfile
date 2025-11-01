pipeline {
  agent any

  options {
    skipDefaultCheckout(true)
    disableConcurrentBuilds()
    timestamps()
  }

  environment {
    IMAGE_NAME   = 'miguel1212/php-simple-app2'
    DOCKER_BUILDKIT = '1'
    VERSION_TAG  = ''
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
          env.VERSION_TAG = sh(
            script: 'DATE_TAG=$(date +%Y%m%d-%H%M%S); GIT_COMMIT=$(git rev-parse --short HEAD); printf "%s-%s" "$DATE_TAG" "$GIT_COMMIT"',
            returnStdout: true
          ).trim()
          echo "🔖 Versión generada: ${env.VERSION_TAG}"
          currentBuild.displayName = "#${env.BUILD_NUMBER} ${env.VERSION_TAG}"
        }
      }
    }

    stage('Verificar Docker') {
      steps {
        sh '''
          echo "🔍 Verificando Docker..."
          docker version
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          echo "🔧 Construyendo imagen..."
          docker build -t $IMAGE_NAME:latest -t $IMAGE_NAME:${VERSION_TAG} .
          docker images | grep "$IMAGE_NAME" || true
        '''
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'docker-hub-creds',
          usernameVariable: 'DOCKERHUB_USER',
          passwordVariable: 'DOCKERHUB_PASS'
        )]) {
          sh '''
            echo "🔐 Login Docker Hub..."
            echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin

            echo "⬆️ Push..."
            docker push $IMAGE_NAME:latest
            docker push $IMAGE_NAME:${VERSION_TAG}

            docker logout || true
          '''
        }
      }
    }

    stage('Cleanup') {
      steps {
        sh 'docker system prune -f || true'
      }
    }
  }

  post {
    success {
      echo "✅ Listo: ${IMAGE_NAME}:${VERSION_TAG}"
    }
    failure {
      echo "❌ Pipeline falló. Revisa los logs."
    }
  }
}
