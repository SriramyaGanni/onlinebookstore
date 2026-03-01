pipeline {
    agent any

    stages {

        stage('Checkout Code') {
            steps {
                checkout scmGit(
                    branches: [[name: '*/master']],
                    userRemoteConfigs: [[
                        credentialsId: 'Sriramya',
                        url: 'https://github.com/SriramyaGanni/onlinebookstore.git'
                    ]]
                )
            }
        }

        stage('Build Artifact') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Archive Artifact') {
            steps {
                archiveArtifacts artifacts: 'target/*.war', fingerprint: true
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t onlinebookstore-image .'
            }
        }

        stage('Run Container') {
            steps {
                sh '''
                docker stop onlinebookstore-container || true
                docker rm onlinebookstore-container || true
                docker run -d \
                  -p 8080:8080 \
                  --name onlinebookstore-container \
                  onlinebookstore-image
                '''
            }
        }
    }
}
