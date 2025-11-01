pipeline {
  agent any

  environment {
    DOCKER_HUB_REPO = 'miguel1212/php-simple-app2'
    // Estas dos se rellenan tras generar VERSION_TAG
    DOCKER_IMAGE      = ''                  // p.ej. miguel1212/indep-docker:20251031-183012-ab12cd3
    DOCKER_TAG_LATEST = ''                  // miguel1212/indep-docker:latest
  }

  stages {

    stage('Checkout') {
      steps {
        echo "📦 Checkout del repositorio"
        checkout scm
      }
    }

    stage('Verificar entorno Docker') {
      steps {
        echo "🔎 Verificando conexión con Docker"
        sh '''
          echo "DOCKER_HOST=${DOCKER_HOST}"
          docker version
        '''
      }
    }

    stage('Generate Tag') {
      steps {
        script {
          def GIT_COMMIT  = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          def DATE_TAG    = sh(script: "date +%Y%m%d-%H%M%S",       returnStdout: true).trim()
          def VERSION_TAG = "${DATE_TAG}-${GIT_COMMIT}"

          env.VERSION_TAG      = VERSION_TAG
          env.DOCKER_IMAGE     = "${env.DOCKER_HUB_REPO}:${VERSION_TAG}"
          env.DOCKER_TAG_LATEST= "${env.DOCKER_HUB_REPO}:latest"

          echo "Versión generada: ${VERSION_TAG}"
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          echo "=== Construyendo imagen ==="
          docker build -t ${DOCKER_IMAGE} .
          docker tag ${DOCKER_IMAGE} ${DOCKER_TAG_LATEST}
        '''
      }
    }

    stage('Prueba rápida (smoke test)') {
      steps {
        echo "🧪 Ejecutando prueba rápida..."
        sh '''
          docker run --rm ${DOCKER_IMAGE} echo "✅ Imagen ejecutada correctamente"
        '''
      }
    }

    stage('Push to DockerHub') {
      steps {
        sh 'echo "=== Subiendo imagen a DockerHub ==="'
        withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
            docker push ${DOCKER_IMAGE}
            docker push ${DOCKER_TAG_LATEST}
            docker logout
          '''
        }
      }
    }

    stage('Desplegar (solo en main)') {
      when { branch 'main' }
      steps {
        echo "🌍 Desplegando la aplicación (solo en main)..."
        sh '''
          docker compose down || true
          docker compose up -d
        '''
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
      echo "→ ${DOCKER_TAG_LATEST}"
      echo "→ ${DOCKER_IMAGE}"
    }
    failure {
      echo "Pipeline falló"
      // Si manejas logs locales, los archivará si existen
      archiveArtifacts artifacts: '**/logs/*.log', allowEmptyArchive: true
    }
  }
}
