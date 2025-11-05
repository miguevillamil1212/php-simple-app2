pipeline {
  agent any
  options {
    // Para que el checkout ocurra cuando y donde lo necesitamos
    skipDefaultCheckout(true)
    timestamps()
  }

  environment {
    IMAGE_NAME = 'miguel1212/php-simple-app2'
    // Credenciales de Docker Hub en Jenkins
    DOCKERHUB = credentials('docker-hub-credentials')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout([
          $class: 'GitSCM',
          branches: [[name: '*/main']],
          userRemoteConfigs: [[url: 'https://github.com/miguevillamil1212/php-simple-app2.git']]
        ])
      }
    }

    stage('Ensure Docker CLI on agent') {
      steps {
        sh '''
          set -eux
          if ! command -v docker >/dev/null 2>&1; then
            echo "Docker CLI no encontrado. Instalando..."
            apt-get update
            # docker.io trae el cliente y se conecta al daemon del host via socket
            apt-get install -y docker.io
          else
            echo "Docker CLI ya está instalado."
          fi

          # Verifica el socket montado (deberías tener /var/run/docker.sock en tu docker-compose)
          if [ ! -S /var/run/docker.sock ]; then
            echo "ERROR: /var/run/docker.sock no está disponible en el agente."
            echo "Asegura en tu docker-compose del Jenkins: -v /var/run/docker.sock:/var/run/docker.sock"
            exit 1
          fi

          docker version
        '''
      }
    }

    stage('Generate Tag') {
      steps {
        script {
          def GIT_COMMIT = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          def DATE_TAG   = sh(script: "date +%Y%m%d-%H%M%S", returnStdout: true).trim()
          env.VERSION_TAG = "${DATE_TAG}-${GIT_COMMIT}"
          echo "Versión generada: ${env.VERSION_TAG}"
        }
      }
    }

    stage('Build image') {
      steps {
        sh """
          set -eux
          docker build -t ${IMAGE_NAME}:${VERSION_TAG} .
          docker tag  ${IMAGE_NAME}:${VERSION_TAG} ${IMAGE_NAME}:latest
        """
      }
    }

    stage('Push to Docker Hub') {
      steps {
        sh """
          set -eux
          echo "${DOCKERHUB_PSW}" | docker login -u "${DOCKERHUB_USR}" --password-stdin
          docker push ${IMAGE_NAME}:${VERSION_TAG}
          docker push ${IMAGE_NAME}:latest
        """
      }
    }
  }

  post {
    success {
      echo "Publicadas:"
      echo "→ ${env.IMAGE_NAME}:latest"
      echo "→ ${env.IMAGE_NAME}:${env.VERSION_TAG}"
    }
    always {
      sh 'docker system prune -f || true'
    }
  }
}
