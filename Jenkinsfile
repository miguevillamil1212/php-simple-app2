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
    APP_ARCHIVE     = 'php-simple-app.tar.gz'
    VERSION_TAG     = ''   // se llenará en "Generate Tag" SIEMPRE
    HAS_DOCKER      = 'false'
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/miguevillamil1212/php-simple-app2.git'
      }
    }

    // Generar Tag SIEMPRE (así exista o no Docker)
    stage('Generate Tag') {
      steps {
        script {
          def GIT_COMMIT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          def DATE_TAG   = sh(script: "date +%Y%m%d-%H%M%S",       returnStdout: true).trim()
          env.VERSION_TAG = "${DATE_TAG}-${GIT_COMMIT}"
          echo "🔖 Versión generada: ${env.VERSION_TAG}"
        }
      }
    }

    stage('Detectar Docker en el nodo') {
      steps {
        script {
          def rc = sh(script: 'command -v docker >/dev/null 2>&1', returnStatus: true)
          env.HAS_DOCKER = (rc == 0) ? 'true' : 'false'
          echo "HAS_DOCKER = ${env.HAS_DOCKER}"
        }
      }
    }

    /* ========= Camino A: hay Docker => build & push ========= */
    stage('Build Docker Image') {
      when { expression { env.HAS_DOCKER == 'true' } }
      steps {
        sh '''
          set -eu
          docker version
          echo "🔧 Construyendo imagen con tag ${VERSION_TAG}"
          docker build \
            -t $IMAGE_NAME:latest \
            -t $IMAGE_NAME:${VERSION_TAG} .
        '''
      }
    }

    stage('Login & Push a Docker Hub') {
      when { expression { env.HAS_DOCKER == 'true' } }
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'docker-hub-creds',
          usernameVariable: 'DOCKERHUB_USER',
          passwordVariable: 'DOCKERHUB_PASS'
        )]) {
          sh '''
            set -eu
            echo "$DOCKERHUB_PASS" | docker login -u "$DOCKERHUB_USER" --password-stdin
            echo "🚀 Subiendo imagen a Docker Hub..."
            docker push $IMAGE_NAME:latest
            docker push $IMAGE_NAME:${VERSION_TAG}
            docker logout || true
          '''
        }
      }
    }

    stage('Cleanup Docker') {
      when { expression { env.HAS_DOCKER == 'true' } }
      steps {
        sh 'docker system prune -f || true'
      }
    }

    /* ========= Camino B: NO hay Docker => empaquetar y archivar ========= */
    stage('Empaquetar app (sin Docker)') {
      when { expression { env.HAS_DOCKER == "false" } }
      steps {
        sh '''
          set -eu
          rm -f "$APP_ARCHIVE"
          tar --exclude-vcs \
              --exclude="./.git" \
              --exclude="./.git/*" \
              --exclude="./**/@tmp/**" \
              -czf "$APP_ARCHIVE" .
        '''
        archiveArtifacts artifacts: "${APP_ARCHIVE}", fingerprint: true
        echo "No hay Docker en el nodo. Se archivó la app como: ${APP_ARCHIVE}"
      }
    }
  }

  post {
    success {
      script {
        // Fallback seguro por si algo raro deja VERSION_TAG vacío
        def tag = (env.VERSION_TAG?.trim()) ? env.VERSION_TAG : "no-docker"
        echo "✅ Pipeline completado con éxito."
        echo "Imagen/versión generada: ${IMAGE_NAME}:${tag}"
      }
    }
    failure {
      echo "❌ Pipeline falló"
    }
  }
}
