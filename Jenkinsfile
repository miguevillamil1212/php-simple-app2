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
  }

  stages {
    stage('Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/miguevillamil1212/php-simple-app2.git'
      }
    }
    stage('Detect Changes') {
            steps {
                script {
                    // Obtiene el último commit del repo local
                    def currentCommit = sh(script: "git rev-parse HEAD", returnStdout: true).trim()

                    // Archivo para guardar el último commit desplegado
                    def commitFile = "${env.WORKSPACE}/.last_commit"

                    if (fileExists(commitFile)) {
                        def lastCommit = readFile(commitFile).trim()
                        if (currentCommit == lastCommit) {
                            echo "No hay cambios nuevos desde el último despliegue (${lastCommit})."
                            currentBuild.result = 'SUCCESS'
                            currentBuild.displayName = "Sin cambios"
                            skipRemainingStages()
                        } else {
                            echo "Cambios detectados. Último commit anterior: ${lastCommit}"
                        }
                    } else {
                        echo "Primer despliegue: no existe registro previo de commit."
                    }

                    // Guarda el commit actual para la próxima ejecución
                    writeFile file: commitFile, text: currentCommit
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
          docker build \
            -t $IMAGE_NAME:latest \
            -t $IMAGE_NAME:${BUILD_NUMBER} .
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
            docker push $IMAGE_NAME:latest
            docker push $IMAGE_NAME:${BUILD_NUMBER}
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
          # Empaqueta todo excepto .git y el workspace temporal de Jenkins
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
    success { echo '✅ Pipeline completado con éxito (Docker push si había Docker; artefacto .tar.gz si no).' }
    failure { echo '❌ Pipeline falló' }
  }
}
