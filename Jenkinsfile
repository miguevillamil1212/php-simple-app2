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
          // Fecha en zona Bogotá + commit corto
          def tz  = java.util.TimeZone.getTimeZone('America/Bogota')
          def fmt = new java.text.SimpleDateFormat('yyyyMMdd-HHmmss'); fmt.setTimeZone(tz)
          def dateTag    = fmt.format(new Date())
          def shortCommit = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          env.VERSION_TAG = "${dateTag}-${shortCommit}"
          echo "🔖 Versión: ${env.VERSION_TAG}"
          currentBuild.displayName = "#${env.BUILD_NUMBER} ${env.VERSION_TAG}"
        }
      }
    }

    stage('Preflight Docker') {
      steps {
        sh '''
          set -eu
          echo "🔍 Verificando Docker en el nodo..."
          if ! command -v docker >/dev/null 2>&1; then
            echo "ERROR: No se encontró el cliente 'docker' en este nodo de Jenkins."
            echo "Solución: ejecutar Jenkins con el socket del host y tener docker-cli dentro del contenedor."
            exit 2
          fi
          # Verifica conexión al daemon
          docker version >/dev/null
          echo "✅ Docker OK"
        '''
      }
    }

    stage('Build') {
      steps {
        sh '''
          echo "🔧 Construyendo imagen..."
          docker build -t ${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${VERSION_TAG} .
        '''
      }
    }

    stage('Push') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'docker-hub-creds',
          usernameVariable: 'DOCKERHUB_USER',
          passwordVariable: 'DOCKERHUB_PASS'
        )]) {
          sh '''
            set -eu
            echo "🔐 Login Docker Hub..."
            echo "${DOCKERHUB_PASS}" | docker login -u "${DOCKERHUB_USER}" --password-stdin
            echo "⬆️ Push de tags..."
            docker push ${IMAGE_NAME}:latest
            docker push ${IMAGE_NAME}:${VERSION_TAG}
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
      echo "✅ Publicado: ${IMAGE_NAME}:${VERSION_TAG}"
    }
    failure {
      echo "❌ Pipeline falló. Revisa la etapa donde se detuvo."
    }
  }
}
