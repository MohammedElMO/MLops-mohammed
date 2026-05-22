pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        GITHUB_USERNAME = "${env.CHANGE_AUTHOR ?: env.BUILD_USER_ID ?: 'jenkins'}"
        EFS_DIR = "${env.WORKSPACE}/efs"
        RAY_TMPDIR = "/tmp/ray_mlopsfull_${env.BUILD_TAG ?: 'local'}"
        RAY_DEDUP_LOGS = "0"
        TOKENIZERS_PARALLELISM = "false"
        PYTHONUNBUFFERED = "1"
        VENV = "/tmp/mlopsfull_venv_${env.BUILD_TAG ?: 'local'}"
    }

    stages {
        stage('Setup') {
            steps {
                dir('/workspace/MLOpsFull') {
                    sh '''
                        rm -rf "$VENV"
                        python3.10 -m venv "$VENV"
                        . "$VENV/bin/activate"
                        python -m pip install --upgrade pip
                        pip install -r requirements.txt
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
    }

    post {
        always {
            archiveArtifacts artifacts: 'logs/*.log', allowEmptyArchive: true
        }
    }
}
