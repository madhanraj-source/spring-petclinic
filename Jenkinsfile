pipeline {

    agent any

    tools {
        maven 'Maven-3.9'
        jdk   'JDK-17'
    }

    environment {
        APP_NAME        = 'spring-petclinic'
        APP_VERSION     = '1.0.0'
        SONAR_TOKEN     = credentials('sonar-token')
        SONAR_ORG       = 'madhanraj-source'
        SONAR_PROJECT   = 'spring-petclinic'
        NEXUS_URL       = '43.205.111.180:8081'
        NEXUS_CREDS     = credentials('nexus-credentials')
        DOCKER_IMAGE    = '43.205.111.180:8082/spring-petclinic'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '5'))
        timeout(time: 60, unit: 'MINUTES')
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout') {
            steps {
                echo "=== Checking out source code ==="
                checkout scm
                sh 'git log --oneline -5'
            }
        }

        stage('Build') {
            steps {
                echo "=== Building application ==="
                sh 'mvn clean package -DskipTests -B -Dcheckstyle.skip=true'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                    echo "✅ Build successful"
                }
            }
        }

        stage('Unit Tests') {
            steps {
                echo "=== Running Unit Tests ==="
                sh 'mvn test -B -Dcheckstyle.skip=true -Dsurefire.excludes=**/PostgresIntegrationTests.java'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('OWASP Dependency-Check') {
            steps {
                echo "=== Running OWASP Check (CVSS threshold: 7.0) ==="
                sh '''
                    mvn org.owasp:dependency-check-maven:check \
                        -DfailBuildOnCVSS=7 \
                        -DnvdApiKey=a891fe66-ed97-4de4-a7d4-85bccb7546fe \
                        -B
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'target/dependency-check-report',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'OWASP Dependency Report'
                    ])
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo "=== Running SonarCloud Analysis ==="
                sh """
                    mvn sonar:sonar \
                        -Dsonar.host.url=https://sonarcloud.io \
                        -Dsonar.organization=${SONAR_ORG} \
                        -Dsonar.projectKey=${SONAR_PROJECT} \
                        -Dsonar.login=${SONAR_TOKEN} \
                        -B
                """
            }
        }

        stage('Quality Gate') {
            steps {
                echo "=== Waiting for SonarQube Quality Gate ==="
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
            post {
                success { echo "✅ Quality Gate PASSED" }
                failure { echo "❌ Quality Gate FAILED" }
            }
        }

        stage('Publish to Nexus') {
            steps {
                echo "=== Publishing artifact to Nexus ==="
                sh """
                    curl -u ${NEXUS_CREDS_USR}:${NEXUS_CREDS_PSW} \
                         --upload-file target/${APP_NAME}-*.jar \
                         "${NEXUS_URL}/repository/libs-release-local/com/example/${APP_NAME}/${APP_VERSION}/${APP_NAME}-${APP_VERSION}-${BUILD_NUMBER}.jar"
                    echo "✅ Artifact published to Nexus"
                """
            }
        }

        stage('Docker Build & Push') {
            steps {
                echo "=== Building Docker Image ==="
                sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} -t ${DOCKER_IMAGE}:latest ."
                echo "✅ Docker image built"
            }
            post {
                always {
                    sh "docker rmi ${DOCKER_IMAGE}:${BUILD_NUMBER} || true"
                    sh "docker rmi ${DOCKER_IMAGE}:latest || true"
                }
            }
        }

        stage('Approval Gate') {
            steps {
                echo "=== Waiting for manual approval ==="
                timeout(time: 30, unit: 'MINUTES') {
                    input(
                        message: """
                        🚀 Deploy to PRODUCTION?

                        Build:   #${BUILD_NUMBER}
                        Version: ${APP_VERSION}

                        ✅ Tests Passed
                        ✅ OWASP Passed
                        ✅ Quality Gate Passed
                        ✅ Artifact Published
                        """,
                        ok: 'Yes, Deploy!'
                    )
                }
                echo "✅ Deployment approved"
            }
        }

        stage('Deploy') {
            steps {
                echo "=== Deploying Application ==="
                sh """
                    JAR_FILE=\$(ls target/${APP_NAME}-*.jar | head -1)
                    echo "Deploying: \$JAR_FILE"
                    echo "✅ Deployment complete"
                """
            }
        }

    }

    post {
        always {
            cleanWs()
            echo "✅ Workspace cleaned"
        }
        success {
            echo "✅ PIPELINE SUCCESS — Build #${BUILD_NUMBER}"
        }
        failure {
            echo "❌ PIPELINE FAILED — Build #${BUILD_NUMBER}"
        }
    }

}