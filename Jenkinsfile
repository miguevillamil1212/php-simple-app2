pipeline {
  agent any

  options {
    skipDefaultCheckout(true)
    disableConcurrentBuilds()
    timestamps()
  }

  environment {
    IMAGE_NAME      = 'miguel1212/php-simple-app2'
    DOCKER_BUILDKIT = '1'
    VERSION_TAG     = ''
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
            script: 'echo $(date +%Y%m%d-%H%M%S)-$(git rev-parse --short HEAD)',
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
          echo "🔍 Verificando conexión con Docker..."
          docker version
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          echo "🔧 Construyendo imagen..."
          docker build -t $IMAGE_NAME:latest -t $IMAGE_NAME:${VERSION_TAG} .
          docker images | grep $IMAGE_NAME
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
            echo "🚀 Iniciando sesión en Docker Hub..."
            echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin

            echo "⬆️ Subiendo imagen..."
            docker push $IMAGE_NAME:latest
            docker push $IMAGE_NAME:${VERSION_TAG}

            docker logout || true
          '''
        }
      }
    }

    stage('Cleanup') {
      steps {
        sh '''
          echo "🧹 Limpiando imágenes locales..."
          docker system prune -f || true
        '''
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline completado con éxito."
      echo "Imagen publicada: ${IMAGE_NAME}:${VERSION_TAG}"
    }
    failure {
      echo "❌ Pipeline falló. Revisa los logs."
    }
  }
}
