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
  }
}