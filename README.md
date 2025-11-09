# Unity Web App hosted in Google Cloud
This project is a full stack, cloud native deployment of how to host a unity WebGL project in Google Cloud.
---

## Technologies Used
- Google Cloud Platform : Cloud Storage, Artifact Registry, Cloud Run, Load Balancing, Certificate Manager
- Azure : Hosting Jenkins VM, DNS Hosted Zones
- Docker : For container packaging
- Jenkins : For CI/CD
- Git/GitHub : Soruce Code Repository
- Terraform : Programaticaly provisioning infrastructure

---

## Useful Links
- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)  
  Official resource for defining GCP resources using Terraform.

- [GCP Cloud Run Documentation](https://cloud.google.com/run/docs/)  
  Fully managed application platform for running containers in GCP

- [Global Load Balancing with Cloud Run](https://docs.cloud.google.com/load-balancing/docs/https/setup-global-ext-https-serverless)  
  Goes over how to route request to serverless backends using an external ALB

- [Jenkins Documentation](https://www.jenkins.io/doc/)  
  Automate CI/CD pipelines to deploy infrastructure and sync content.

- [Unity Documentation](https://docs.unity.com/en-us)  
  For learning how to use the Unity game engine

---

## Security & Best Practices

---
# Architecture Diagram
![Cloud Run Architecture](architecture_diagram_v1.png)
---

## How-To Guide

### Step 1: GitHub and Terraform Setup  
Create a new GitHub repository to manage your source code with version control. Clone this repository locally to organize your Terraform files, scripts, and other resources. This repo will also integrate with Jenkins later for automated deployments.

### Step 2: GCS Bucket Creation
Use Terraform to provision a bucket in GCS. This will be used to store our terraform state so we aren't storing this locally.

### Step 3: Establishing GCP and Jenkins connections
Create a new service account in GCP and create a JSON key with it as we will let Jenkins use this account for managing/creating resources. In our Github repo create a webhook and point it at your Jenkins VM. We also need to create a Github SSH key to let Jenkins authenticate with our private repos.

### Step 4: DockerFile creation and first pipeline stages
Create a basic Dockerfile using nginx:alpine as our base and copying our nginx.conf and unity build files to their respective locations. We can expose 8080 on the container.
In our Jenkinsfile we will set up our environment variables required for building the image *LOCATION* , *PROJECT ID*, *REPOSITORY*, and *IMAGE*.  
Pipeline stages we are adding are
- Stage 1 : Clone our main branch using our Github SSH key we created earlier.
- Stage 2 : Docker.Build step that uses our Dockerfile to build an image

### Step 5: Terraform Set-Up
We need to now create our terraform files. Create a terraform.tf to store our provider info, a main.tf for resources and then a variables.tf for any variables. I've put this all under an infrastructure folder.
- terraforrm.tf : Add a provider block an include google as well as google beta. We also want to provision a GCS bucket an point our backend to use it
- variables.tf : add any repeatable values as variables incase we ever want to modularize this set up
- main.tf : create a artifact registry repository resource (we will store our images here)