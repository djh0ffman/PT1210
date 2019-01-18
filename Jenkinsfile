pipeline {
  agent any
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
              sh 'make bin/pt1210.exe DEBUG=1'
              sh 'mkdir gcc-debug'
              sh 'mv bin/pt1210.exe gcc-debug/pt1210.exe'
              archiveArtifacts(artifacts: 'gcc-debug/pt1210.exe', fingerprint: true)
              deleteDir()
            }

          }
        }
        stage('GCC Release') {
          steps {
            ws(dir: "${WORKSPACE}-gcc-release") {
              unstash 'source'
              sh 'make bin/pt1210.exe'
              sh 'mkdir gcc-release'
              sh 'mv bin/pt1210.exe gcc-release/pt1210.exe'
              archiveArtifacts(artifacts: 'gcc-release/pt1210.exe', fingerprint: true)
              deleteDir()
            }

          }
        }
      }
    }
    stage('Discord Notifier') {
      environment {
        DISCORD_WEBHOOK_URL = credentials('pt1210-discord-webhook-url')
        GIT_COMMIT_SHORT = GIT_COMMIT.substring(0, 7)
        GITHUB_COMMIT_URL = "${GIT_URL.substring(0, GIT_URL.length() - 4)}/commit/${GIT_COMMIT}"
      }
      steps {
        sh 'printenv'
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
}
