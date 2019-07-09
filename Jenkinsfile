pipeline {
  agent any
  environment {
    AMIGA_GCC = '/opt/amiga'
    DISCORD_WEBHOOK_URL = credentials('pt1210-discord-webhook-url')
    GIT_COMMIT_SHORT = GIT_COMMIT.substring(0, 7)
    GITHUB_COMMIT_URL = "${GIT_URL.substring(0, GIT_URL.length() - 4)}/commit/${GIT_COMMIT}"
  }
  stages {
    stage('Checkout') {
      steps {
        stash name: 'source', useDefaultExcludes: false
        deleteDir()
      }
    }
    stage('Build') {
      parallel {
        stage('GCC Debug') {
          steps {
            ws(dir: "${WORKSPACE}-gcc-debug") {
              unstash 'source'
              sh 'cmake . -Bbuild-debug -DCMAKE_TOOLCHAIN_FILE=cmake/amiga-gcc-toolchain.cmake -DCMAKE_BUILD_TYPE=Debug'
              sh 'cmake --build build-debug'
              archiveArtifacts(artifacts: 'bin/pt1210-debug.exe', fingerprint: true)
              deleteDir()
            }

          }
        }
        stage('GCC Release') {
          steps {
            ws(dir: "${WORKSPACE}-gcc-release") {
              unstash 'source'
              sh 'cmake . -Bbuild-release -DCMAKE_TOOLCHAIN_FILE=cmake/amiga-gcc-toolchain.cmake'
              sh 'cmake --build build-release'
              archiveArtifacts(artifacts: 'bin/pt1210.exe', fingerprint: true)
              deleteDir()
            }

          }
        }
      }
    }
  }
  post {
    always {
      script {
        try {
          discordSend description: "Commit: [`${env.GIT_COMMIT_SHORT}`](${env.GITHUB_COMMIT_URL})\nBuild **${currentBuild.currentResult}**!", link: env.RUN_DISPLAY_URL, result: currentBuild.currentResult, title: "${env.JOB_NAME} build ${env.BUILD_DISPLAY_NAME}", webhookURL: env.DISCORD_WEBHOOK_URL
        } catch (err) {
          echo "Discord notification failed: ${err}"
        }
      }
    }
  }
}
