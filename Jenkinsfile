pipeline {
    agent any

    stages {

        stage('Checkout Code') {
            steps {
                checkout scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: 'Sriramya', url: 'https://github.com/SriramyaGanni/onlinebookstore.git']])
            }
        }

        stage('Build Artifact') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Archive Artifact') {
            steps {
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t online-bookstore-image .'
            }
        }

        stage('Run Container') {
            steps {
                sh '''
                docker stop online-bookstore-container || true
                docker rm online-bookstore-container || true
                docker run -d \
                  -p 8080:8080 \
                  --name online-bookstore-container \
                  online-bookstore-image
                '''
            }
        }
    }
}
