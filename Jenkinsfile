def dockerImage

pipeline {
    agent any

    environment {
        // For Docker Image Name
        LOCATION = "us-west2"
        PROJECTID = "MY-PROJECT-ID"
        REPOSITORY = "MY-REPO"
        IMAGE = "MY-IMAGE"
    }

    stages {
        stage('Clone Repo') {
            steps {
                git branch: 'main', credentialsId: 'Github_SSH', url: 'git@github/name/repo.git'
            }
        }

        stage('Build docker container') {
            steps {
                script {
                    echo "Building Docker image: ${LOCATION}-docker.pkg.dev/${PROJECTID}/${REPOSITORY}/${IMAGE}"
                    dockerImage = docker.build("${LOCATION}-docker.pkg.dev/${PROJECTID}/${REPOSITORY}/${IMAGE}:latest", ".")
                }
            }
        }

        stage('Authenticate to Google Cloud Artifact Repo') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'svc_jenkins_gc', variable: 'svc_jenkins')]) {
                            sh ''' 
                                gcloud auth activate-service-account --key-file="$svc_jenkins" --project="${PROJECTID}"
                                gcloud auth configure-docker ${LOCATION}-docker.pkg.dev --quiet
                            '''
                    } 
               }
            }
        }

        stage('Push Docker Image to Artifact Repo') {
            steps {
                script {
                    echo "Pushing newly created image to ${REPOSITORY}"
                    dockerImage.push("latest")
                }
            }
        }

        stage('Terraform Build') {
            steps {
                dir('infrastructure') {
                    script {
                        withCredentials([file(credentialsId: 'svc_jenkins_gc', variable: 'svc_jenkins')]) {
                            withEnv(["GOOGLE_APPLICATION_CREDENTIALS=$svc_jenkins"]) {
                            sh '''
                                terraform fmt 
                                terraform init -input=false
                                terraform plan -out=tfplan -input=false
                                terraform apply -auto-approve tfplan
                            '''
                            }
                        }
                    }
                }
            }
        }
        
    }
}