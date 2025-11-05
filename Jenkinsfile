pipeline {
  agent any
  options {
    skipDefaultCheckout(true)
    timestamps()
  }

  environment {
    IMAGE_NAME = 'miguel1212/php-simple-app2'
    DOCKERHUB = credentials('docker-hub-credentials') // DOCKERHUB_USR / DOCKERHUB_PSW
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

    stage('Prepare Docker CLI (no root)') {
      steps {
        sh '''
          set -eux

          # Comprueba socket Docker
          if [ ! -S /var/run/docker.sock ]; then
            echo "ERROR: /var/run/docker.sock no está disponible en el agente."
            echo "Asegura montar el socket en el contenedor de Jenkins: -v /var/run/docker.sock:/var/run/docker.sock"
            exit 1
          fi

          # Si ya hay docker en PATH, úsalo
          if command -v docker >/dev/null 2>&1; then
            echo "Docker CLI ya presente:"
            docker version
            exit 0
          fi

          echo "Docker CLI no encontrado: usando binario estático en el workspace"
          mkdir -p .docker-cli
          cd .docker-cli

          # Elige una versión estable del CLI (ajústala si quieres)
          DOCKER_CLI_VERSION="26.1.4"
          URL="https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz"

          curl -fsSL "$URL" -o docker.tgz
          tar -xzf docker.tgz
          # Deja solo el binario docker
          mv docker/docker ../docker || true
          cd ..
          chmod +x docker

          # Prepend a PATH para esta ejecución
          echo "export PATH=\"$PWD:$PATH\"" > .env_path
          . ./.env_path

          docker version
        '''
      }
    }

    stage('Generate Tag') {
      steps {
        sh '''
          set -eu
          # Asegura el docker que acabamos de poner en PATH, si aplica
          [ -f .env_path ] && . ./.env_path || true

          GIT_COMMIT=$(git rev-parse --short HEAD)
          DATE_TAG=$(date +%Y%m%d-%H%M%S)
          echo "VERSION_TAG=${DATE_TAG}-${GIT_COMMIT}" > .build_vars
          cat .build_vars
        '''
      }
    }

    stage('Build image') {
      steps {
        sh '''
          set -eux
          [ -f .env_path ] && . ./.env_path || true
          . ./.build_vars

          docker build -t ${IMAGE_NAME}:${VERSION_TAG} .
          docker tag  ${IMAGE_NAME}:${VERSION_TAG} ${IMAGE_NAME}:latest
        '''
      }
    }

    stage('Push to Docker Hub') {
      steps {
        sh '''
          set -eux
          [ -f .env_path ] && . ./.env_path || true
          . ./.build_vars

          echo "${DOCKERHUB_PSW}" | docker login -u "${DOCKERHUB_USR}" --password-stdin
          docker push ${IMAGE_NAME}:${VERSION_TAG}
          docker push ${IMAGE_NAME}:latest
        '''
      }
    }
  }

  post {
    success {
      sh '''
        . ./.build_vars
        echo "Publicadas:"
        echo "→ ${IMAGE_NAME}:latest"
        echo "→ ${IMAGE_NAME}:${VERSION_TAG}"
      '''
    }
    always {
      sh '''
        [ -f .env_path ] && . ./.env_path || true
        docker system prune -f || true
      '''
    }
  }
}
