pipeline {
  agent any

  options {
    skipDefaultCheckout(true)
    disableConcurrentBuilds()
    timestamps()
  }

  environment {
    IMAGE_NAME     = 'miguel1212/php-simple-app2'
    DOCKER_BUILDKIT = '1'
    VERSION_TAG    = ''
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
          // Fecha con zona de Bogotá para consistencia visual
          def tz   = java.util.TimeZone.getTimeZone('America/Bogota')
          def fmt  = new java.text.SimpleDateFormat('yyyyMMdd-HHmmss'); fmt.setTimeZone(tz)
          def dateTag    = fmt.format(new Date())
          def shortCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()

          def vt = "${dateTag}-${shortCommit}"
          echo "🔖 Versión generada local: ${vt}"

          env.VERSION_TAG = vt
          currentBuild.displayName = "#${env.BUILD_NUMBER} ${env.VERSION_TAG}"
        }
      }
    }

    stage('Build & Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'docker-hub-creds',
          usernameVariable: 'DOCKERHUB_USER',
          passwordVariable: 'DOCKERHUB_PASS'
        )]) {
          sh '''
            set -eu
            echo "🔍 Verificando Docker..."
            docker version

            echo "🔧 Construyendo imagen ${IMAGE_NAME}:${VERSION_TAG} y :latest"
            docker build -t ${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${VERSION_TAG} .

            echo "🔐 Login en Docker Hub..."
            echo "${DOCKERHUB_PASS}" | docker login -u "${DOCKERHUB_USER}" --password-stdin

            echo "⬆️ Push de tags..."
            docker push ${IMAGE_NAME}:latest
            docker push ${IMAGE_NAME}:${VERSION_TAG}

            docker logout || true
            echo "🧹 Limpieza..."
            docker system prune -f || true
          '''
        }
      }
    }
  }

  post {
    success {
      echo "✅ Publicado: ${IMAGE_NAME}:${VERSION_TAG}"
    }
    failure {
      echo "❌ Pipeline falló. Revisa si Docker está disponible dentro de Jenkins."
    }
  }
}
