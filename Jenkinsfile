pipeline {
agent any

tools {
    maven 'maven'
    jdk 'jdk17'
}

environment {

    DOCKER_IMAGE = "sriramyaganni/onlinebookstore"
    AWS_REGION = "ap-southeast-2"
    CLUSTER_NAME = "mycluster"
    RECIPIENTS = "gannisriramya26@gmail.com"
}

stages {

    stage('Clone Repo') {

        steps {

            git branch: 'master',
            url: 'https://github.com/SriramyaGanni/onlinebookstore.git'
        }
    }

    stage('Build Maven') {

        steps {

            sh 'mvn clean package'
        }
    }

    stage('SonarQube Analysis') {

        steps {

            withSonarQubeEnv('SonarQube') {
                sh 'mvn sonar:sonar'
            }
        }
    }

    stage('Quality Gate') {

        steps {

            timeout(time: 2, unit: 'MINUTES') {
                waitForQualityGate abortPipeline: true
            }
        }
    }

    stage('Artifact Upload to Nexus') {

        steps {

            withMaven(
                globalMavenSettingsConfig: 'settings.xml',
                jdk: 'jdk17',
                maven: 'maven',
                traceability: true
            ) {

                sh 'mvn deploy'
            }
        }
    }

    stage('Docker Build') {

        steps {

            sh '''
            docker build -t $DOCKER_IMAGE:${BUILD_NUMBER} .

            docker tag $DOCKER_IMAGE:${BUILD_NUMBER} \
            $DOCKER_IMAGE:latest
            '''
        }
    }

    stage('Docker Push') {

        steps {

            withCredentials([usernamePassword(
                credentialsId: 'dockerhub',
                usernameVariable: 'DOCKER_USER',
                passwordVariable: 'DOCKER_PASS'
            )]) {

                sh '''
                echo $DOCKER_PASS | docker login \
                -u $DOCKER_USER --password-stdin

                docker push $DOCKER_IMAGE:${BUILD_NUMBER}

                docker push $DOCKER_IMAGE:latest

                docker logout
                '''
            }
        }
    }

    stage('Install Helm') {

        steps {

            sh '''
            curl -LO https://get.helm.sh/helm-v3.14.0-linux-amd64.tar.gz
            tar -zxvf helm-v3.14.0-linux-amd64.tar.gz
            mv linux-amd64/helm ./helm
            chmod +x ./helm
            '''
        }
    }

    stage('Setup Kubeconfig') {

        steps {

            sh '''
            aws eks update-kubeconfig \
            --region $AWS_REGION \
            --name $CLUSTER_NAME
            kubectl get nodes
            '''
        }
    }

    stage('Deploy Monitoring Stack') {

        steps {

            sh '''
            ./helm repo add prometheus-community \
            https://prometheus-community.github.io/helm-charts || true
            ./helm repo update
            ./helm upgrade --install monitoring \
            prometheus-community/kube-prometheus-stack \
            --namespace monitoring \
            --create-namespace \
            --set grafana.service.type=LoadBalancer
            '''
        }
    }

    stage('Get Grafana Password') {

        steps {

            sh '''
            echo "Grafana Password:"
            kubectl get secret monitoring-grafana \
            -n monitoring \
            -o jsonpath="{.data.admin-password}" | base64 --decode
            echo ""
            '''
        }
    }

    stage('Deploy Application to EKS') {

        steps {
            sh '''
            kubectl apply -f deployment.yml
            kubectl apply -f service.yml
            '''
        }
    }

    stage('Wait for LoadBalancer') {

        steps {

            sh '''
            echo "Waiting for LoadBalancer..."
            sleep 60
            '''
        }
    }

    stage('Get Application URL') {

        steps {

            script {

                def url = sh(
                    script: '''
                    kubectl get svc onlinebookstore-service \
                    -o jsonpath="{.status.loadBalancer.ingress[0].hostname}{.status.loadBalancer.ingress[0].ip}"
                    ''',
                    returnStdout: true
                ).trim()

                env.APP_URL = url

                echo "Application URL: ${env.APP_URL}"
            }
        }
    }
}

post {

    success {

        emailext(
            subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",

            body: """

Build SUCCESS 🎉

Application URL:
http://${env.APP_URL}

Jenkins URL:
${env.BUILD_URL}
""",
            to: "${RECIPIENTS}"
        )
    }

    failure {

        emailext(
            subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
            body: """
Build FAILED ❌

Check Logs:
${env.BUILD_URL}
""",
            to: "${RECIPIENTS}"
        )
    }

    always {

        archiveArtifacts artifacts: '**/target/*.jar',
        fingerprint: true
      }
   }
}
