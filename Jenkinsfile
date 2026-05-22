pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        GITHUB_USERNAME = "${env.CHANGE_AUTHOR ?: env.BUILD_USER_ID ?: 'jenkins'}"
        EFS_DIR = "${env.WORKSPACE}/efs"
        RAY_TMPDIR = "/tmp/ray_ci"
        RAY_DEDUP_LOGS = "0"
        TOKENIZERS_PARALLELISM = "false"
        PYTHONUNBUFFERED = "1"
        HF_HOME = "/tmp/hf_cache"
        TRANSFORMERS_CACHE = "/tmp/hf_cache"
        VENV = "/tmp/mlopsfull_venv"
        IMAGE_NAME = "mlopsfull"
    }

    stages {
        stage('Setup') {
            steps {
                dir('/workspace/MLOpsFull') {
                    sh '''
                        git config --global --add safe.directory /workspace/MLOpsFull || true
                        if [ ! -x "$VENV/bin/python" ] || [ ! -x "$VENV/bin/pip" ]; then
                            rm -rf "$VENV"
                            python3.10 -m venv "$VENV"
                        fi
                        . "$VENV/bin/activate"
                        if [ ! -f "$VENV/.deps_installed" ] || [ requirements.txt -nt "$VENV/.deps_installed" ]; then
                            pip install -r requirements.txt
                            touch "$VENV/.deps_installed"
                        else
                            echo "Dependencies already installed; skipping pip install."
                        fi
                    '''
                }
            }
        }

        stage('Checks') {
            steps {
                dir('/workspace/MLOpsFull') {
                    sh '''
                        . "$VENV/bin/activate"
                        python -m pip check
                        python -c "from madewithml import config, data, models, train, utils; print('imports ok')"
                        python -c "from madewithml.config import logger; logger.info('jenkins logging smoke test'); print('logging ok')"
                    '''
                }
            }
        }

        stage('Workloads') {
            when {
                anyOf {
                    changeRequest target: 'main'
                    branch 'main'
                }
            }
            steps {
                dir('/workspace/MLOpsFull') {
                    sh '''
                        . "$VENV/bin/activate"
                        bash scripts/ci_build.sh
                    '''
                }
            }
            post {
                always {
                    sh '''
                        mkdir -p results logs
                        cp -f /workspace/MLOpsFull/results/*.json results/ 2>/dev/null || true
                        cp -f /workspace/MLOpsFull/logs/*.log logs/ 2>/dev/null || true
                    '''
                    archiveArtifacts artifacts: 'results/*.json, logs/*.log', allowEmptyArchive: true
                }
            }
        }

        stage('Serve Validation') {
            when {
                branch 'main'
            }
            steps {
                dir('/workspace/MLOpsFull') {
                    sh '''
                        . "$VENV/bin/activate"
                        python -c "from madewithml.serve import app, ModelDeployment; print('serve imports ok')"
                    '''
                }
            }
        }

        stage('Docker Build') {
            when {
                anyOf {
                    changeRequest target: 'main'
                    branch 'main'
                }
            }
            steps {
                dir('/workspace/MLOpsFull') {
                    sh '''
                        git config --global --add safe.directory /workspace/MLOpsFull || true
                        GIT_SHA="${GIT_COMMIT:-$(git rev-parse HEAD)}"
                        GIT_SHA="$(echo "$GIT_SHA" | cut -c1-7)"
                        docker build -t "$IMAGE_NAME:$GIT_SHA" -t "$IMAGE_NAME:ci" .
                    '''
                }
            }
        }

        stage('Docker Push') {
            when {
                branch 'main'
            }
            steps {
                dir('/workspace/MLOpsFull') {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-token', usernameVariable: 'DOCKERHUB_USERNAME', passwordVariable: 'DOCKERHUB_TOKEN')]) {
                        sh '''
                            git config --global --add safe.directory /workspace/MLOpsFull || true
                            GIT_SHA="${GIT_COMMIT:-$(git rev-parse HEAD)}"
                            GIT_SHA="$(echo "$GIT_SHA" | cut -c1-7)"
                            docker tag "$IMAGE_NAME:$GIT_SHA" "$DOCKERHUB_USERNAME/$IMAGE_NAME:$GIT_SHA"
                            docker tag "$IMAGE_NAME:$GIT_SHA" "$DOCKERHUB_USERNAME/$IMAGE_NAME:latest"
                            echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin
                            docker push "$DOCKERHUB_USERNAME/$IMAGE_NAME:$GIT_SHA"
                            docker push "$DOCKERHUB_USERNAME/$IMAGE_NAME:latest"
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            sh '''
                mkdir -p results logs
                cp -f /workspace/MLOpsFull/results/*.json results/ 2>/dev/null || true
                cp -f /workspace/MLOpsFull/logs/*.log logs/ 2>/dev/null || true
            '''
            archiveArtifacts artifacts: 'logs/*.log', allowEmptyArchive: true
        }
    }
}
