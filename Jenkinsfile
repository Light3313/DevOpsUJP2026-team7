
pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    environment {
        IMAGE_NAME = 'devopsujp2026-mediawiki'
    }

    stages {
        stage('Validate Release Tag') {
            steps {
                script {
                    def releaseTag = env.TAG_NAME ?: ''

                    if (!(releaseTag ==~ /^v[0-9]+\.[0-9]+\.[0-9]+$/)) {
                        error("Invalid release tag: ${releaseTag}")
                    }

                    echo "Building release: ${releaseTag}"
                }
            }
        }

        stage('Checkout Source') {
            steps {
                checkout scm

                sh '''
                    echo "Git commit:"
                    git log -1 --format='%h %s'

                    echo "Git tag:"
                    git tag --points-at HEAD
                '''
            }
        }

        stage('Validate Docker Compose') {
            steps {
                sh '''
                    cp .env.example .env
                    docker compose config -q
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build --pull \
                      -t "${IMAGE_NAME}:${TAG_NAME}" \
                      .
                '''
            }
        }

        stage('Smoke Test') {
            steps {
                sh '''
                    docker run --rm \
                      --entrypoint sh \
                      "${IMAGE_NAME}:${TAG_NAME}" \
                      -c '
                        php -v &&
                        apache2ctl -t &&
                        test -f /var/www/html/index.php
                      '
                '''
            }
        }

        stage('Release Summary') {
            steps {
                echo "Release ${env.TAG_NAME} built successfully"
                echo "Image: ${env.IMAGE_NAME}:${env.TAG_NAME}"
            }
        }
    }

    post {
        always {
            sh 'rm -f .env'
        }

        success {
            echo 'Jenkins release pipeline succeeded!'
        }

        failure {
            echo 'Jenkins release pipeline failed!'
        }
    }
}
