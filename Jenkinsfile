pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
        timeout(time: 20, unit: 'MINUTES')
        timestamps()
    }

    environment {
        IMAGE_REPO = 'ghcr.io/light3313/devopsujp2026-team7'
    }

    stages {
        stage('Select published CI image') {
            steps {
                script {
                    if (!((env.TAG_NAME ?: '') ==~ /^v[0-9]+\.[0-9]+\.[0-9]+$/)) {
                        error('Release must be triggered by a tag such as v1.0.0')
                    }
                }
                checkout scm
                script {
                    env.COMMIT_SHA = sh(script: 'git rev-parse HEAD', returnStdout: true).trim()
                    if (!(env.COMMIT_SHA ==~ /^[0-9a-f]{40}$/)) {
                        error('Invalid commit SHA')
                    }
                    env.CI_IMAGE = "${env.IMAGE_REPO}:sha-${env.COMMIT_SHA}"
                    echo "Release ${env.TAG_NAME}: ${env.CI_IMAGE}"
                }
            }
        }

        stage('Deploy MediaWiki') {
            steps {
                withCredentials([sshUserPrivateKey(
                    credentialsId: 'mediawiki-deploy-ssh',
                    keyFileVariable: 'DEPLOY_KEY',
                    usernameVariable: 'DEPLOY_USER'
                )]) {
                    sh '''#!/usr/bin/env bash
set -euo pipefail
: "${DEPLOY_HOST:?Configure DEPLOY_HOST in Jenkins environment}"

ssh -T \
    -o BatchMode=yes \
    -o IdentitiesOnly=yes \
    -o StrictHostKeyChecking=yes \
    -i "$DEPLOY_KEY" \
    -p "${DEPLOY_PORT:-22}" \
    "$DEPLOY_USER@$DEPLOY_HOST" \
    "bash -se -- '$CI_IMAGE'" <<'REMOTE'
set -euo pipefail

image="$1"
cd /opt/app

# Pull the image already built and tested by GitHub Actions.
docker pull "$image"

# Pin the deployment to the immutable digest of the pulled image.
image_ref="$(docker image inspect --format '{{index .RepoDigests 0}}' "$image")"
case "$image_ref" in
    ghcr.io/light3313/devopsujp2026-team7@sha256:*) ;;
    *) echo "Unexpected image reference: $image_ref" >&2; exit 1 ;;
esac

# Store a small image-only override outside the application repository.
override_dir="$HOME/.config/mediawiki-cd"
mkdir -p "$override_dir"
override="$override_dir/compose.release.yaml"
printf 'services:\n  wiki:\n    image: %s\n' "$image_ref" > "$override.tmp"
mv "$override.tmp" "$override"

# Recreate only the wiki service of the verified production project.
docker compose \
    -p app \
    -f /opt/app/docker-compose.yml \
    -f "$override" \
    up -d --no-deps --no-build wiki

printf 'Deployed MediaWiki image: %s\n' "$image_ref"
REMOTE
'''
                }
            }
        }
    }

    post {
        success {
            echo "Docker Compose deployment completed for ${env.TAG_NAME}; verify the website manually."
        }
        failure {
            echo 'Deployment failed; no automatic rollback is configured.'
        }
    }
}
