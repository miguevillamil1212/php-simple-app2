pipeline {
  agent any

  options {
    timestamps()
  }

  environment {
    DOCKER_HUB_REPO   = 'miguel1212/php-simple-app2'
    // Se completan después de generar VERSION_TAG
    DOCKER_IMAGE      = ''     // p.ej. miguel1212/php-simple-app2:20251031-183012-ab12cd3
    DOCKER_TAG_LATEST = ''     // miguel1212/php-simple-app2:latest
    VERSION_TAG       = ''

    // Opcional: acelerar y estandarizar builds
    DOCKER_BUILDKIT = '1'
    COMPOSE_DOCKER_CLI_BUILD = '1'
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
          echo "Usuario actual: $(id)"
          echo "DOCKER_HOST=${DOCKER_HOST}"
          echo "Socket/pipe de Docker:"
          ls -l /var/run/docker.sock 2>/dev/null || echo "(named pipe en Windows)"

          # Falla controlada si no hay acceso al daemon
          docker info >/dev/null 2>&1 || {
            echo "ERROR: Jenkins no puede acceder al daemon de Docker.";
            echo "Si estás en Windows con Docker Desktop, monta //./pipe/docker_engine en /var/run/docker.sock";
            exit 1;
          }
          docker version
        '''
      }
    }

    stage('Generate Tag') {
      steps {
        script {
          def GIT_COMMIT  = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          def DATE_TAG    = sh(script: "date +%Y%m%d-%H%M%S",       returnStdout: true).trim()
          env.VERSION_TAG = "${DATE_TAG}-${GIT_COMMIT}"

          env.DOCKER_IMAGE       = "${env.DOCKER_HUB_REPO}:${env.VERSION_TAG}"
          env.DOCKER_TAG_LATEST  = "${env.DOCKER_HUB_REPO}:latest"

          echo "🔖 Versión generada: ${env.VERSION_TAG}"
          echo "🔖 Imagen: ${env.DOCKER_IMAGE}"
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          echo "🔧 Construyendo imagen"
          docker build --pull --progress=plain -t ${DOCKER_IMAGE} .
          docker tag ${DOCKER_IMAGE} ${DOCKER_TAG_LATEST}
          docker images | grep -E "${DOCKER_HUB_REPO}" || true
        '''
      }
    }

    stage('Prueba rápida (smoke test)') {
      steps {
        echo "🧪 Ejecutando smoke test..."
        sh '''
          # Usar /bin/sh como entrypoint neutro para evitar depender del ENTRYPOINT del Dockerfile
          if docker run --rm --entrypoint /bin/sh ${DOCKER_IMAGE} -lc 'echo "✅ Imagen ejecutada correctamente"'; then
            echo "Smoke test OK"
          else
            echo "ERROR: Smoke test falló"; exit 1
          fi
        '''
      }
    }

    stage('Push to DockerHub') {
      steps {
        echo "🚀 Subiendo imagen a Docker Hub"
        withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh '''
            echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin

            # Reintentos por si hay throttling o fallos transitorios
            n=0
            until [ $n -ge 3 ]; do
              docker push ${DOCKER_IMAGE}  && break
              n=$((n+1)); echo "Reintentando push de ${DOCKER_IMAGE} ($n/3)"; sleep 3
            done

            n=0
            until [ $n -ge 3 ]; do
              docker push ${DOCKER_TAG_LATEST} && break
              n=$((n+1)); echo "Reintentando push de ${DOCKER_TAG_LATEST} ($n/3)"; sleep 3
            done

            docker logout || true
          '''
        }
      }
    }

    stage('Desplegar (solo en main)') {
      when { branch 'main' }
      steps {
        echo "🌍 Desplegando la aplicación (solo en main)..."
        sh '''
          if docker compose version >/dev/null 2>&1; then
            docker compose down || true
            docker compose up -d
          elif docker-compose version >/dev/null 2>&1; then
            docker-compose down || true
            docker-compose up -d
          else
            echo "ERROR: No se encontró docker compose ni docker-compose"; exit 1
          fi
        '''
      }
    }
  }

  post {
    always {
      echo "🧹 Limpieza final"
      sh 'docker system prune -f || true'
    }
    success {
      echo "✅ Pipeline completado con éxito"
      echo "Se subieron las siguientes versiones:"
      echo "→ ${DOCKER_TAG_LATEST}"
      echo "→ ${DOCKER_IMAGE}"
    }
    failure {
      echo "❌ Pipeline falló. Revisa los logs."
      archiveArtifacts artifacts: '**/logs/*.log', allowEmptyArchive: true
    }
  }
}
