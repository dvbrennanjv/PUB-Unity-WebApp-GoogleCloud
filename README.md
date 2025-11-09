# Unity Web App Hosted in Google Cloud

This project demonstrates a full CI/CD pipeline for deploying a Unity WebGL game as a containerized web application on Google Cloud Run, with Terraform-managed infrastructure, a global HTTPS load balancer, and a custom domain secured via a Google-managed SSL certificate.

---

## Technologies Used
- **Google Cloud Platform**: Cloud Storage, Artifact Registry, Cloud Run, Load Balancing, Certificate Manager  
- **Azure**: Hosting Jenkins VM, DNS Hosted Zones  
- **Docker**: Container packaging  
- **Jenkins**: CI/CD automation  
- **Git/GitHub**: Source code repository  
- **Terraform**: Programmatically provisioning infrastructure

---

## Useful Links
- [Terraform GCP Provider Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)  
  Official resource for defining GCP resources using Terraform.

- [GCP Cloud Run Documentation](https://cloud.google.com/run/docs/)  
  Fully managed application platform for running containers in GCP.

- [Global Load Balancing with Cloud Run](https://cloud.google.com/load-balancing/docs/https/setup-global-ext-https-serverless)  
  Guide on how to route requests to serverless backends using an external HTTPS load balancer.

- [Jenkins Documentation](https://www.jenkins.io/doc/)  
  Automate CI/CD pipelines to deploy infrastructure and sync content.

- [Unity Documentation](https://docs.unity.com/en-us)  
  Learn how to use the Unity game engine.

---

## Security & Best Practices

1. **Keep Bucket Names Private**  
   Bucket names should always be stored in a `terraform.tfvars` or `locals.tf` file and should be part of your `.gitignore`.  
   Public exposure could lead to brute-force object discovery or abuse.

2. **Use Principle of Least Privilege**  
   When creating your service account in GCP, only give it permissions necessary for its tasks.  
   Avoid granting excessive permissions to this account.

3. **Terraform State**  
   Terraform state files should always be ignored in `.gitignore` if stored locally.  
   It’s recommended to use a remote backend such as a *GCS Bucket* and limit access to it.  
   Terraform state can contain sensitive information (like public IPs), so always restrict who can access it.

4. **Tagging Infrastructure**  
   Tagging is a best practice in infrastructure management, especially in production environments.  
   I’ve intentionally left out tags, as tagging strategies should be tailored to your organization’s workflow and standards.  
   Define a consistent tagging policy that outlines required tags (e.g., `Environment`, `Owner`, `CostCenter`) and ensures meaningful metadata is applied to all resources for visibility, cost tracking, and governance.

5. **Cloud Armor Policies**  
   Cloud Armor is a powerful service that acts as a web application firewall for Cloud Run.  
   Since Cloud Run is billed per request, creating a good ruleset can help reduce cost and ensure that only authorized users can access your application.

---

## Architecture Diagram
![Cloud Run Architecture](architecture_diagram_v2.png)  

---

## Deployment Walkthrough

### Step 1: GitHub and Terraform Setup
Create a new GitHub repository to manage your source code with version control.  
Clone this repository locally to organize your Terraform files, scripts, and other resources.  
This repository will also integrate with Jenkins later for automated deployments.

### Step 2: GCS Bucket Creation
Use Terraform to provision a bucket in GCS.  
This bucket will be used to store your Terraform state so it isn’t stored locally.

### Step 3: Establish GCP and Jenkins Connections
Create a new service account in GCP and generate a JSON key for it.  
Jenkins will use this account to manage and create GCP resources.  
In your GitHub repository, create a webhook pointing to your Jenkins VM.  
Also create a GitHub SSH key so Jenkins can authenticate with your private repository.

### Step 4: Dockerfile Creation and Build Stages
Create a basic Dockerfile using `nginx:alpine` as the base image and copy your `nginx.conf` and Unity build files to their respective locations.  
Expose port 8080 on the container.

In your Jenkinsfile, set environment variables required for building the image:  
`LOCATION`, `PROJECT_ID`, `REPOSITORY`, and `IMAGE`.

Pipeline stages to add:
- **Stage 1:** Clone the main branch using your GitHub SSH key.
- **Stage 2:** `docker.build` step that uses the Dockerfile to build an image.

### Step 5: Terraform Setup
Create the Terraform files:  
`terraform.tf` for provider info, `main.tf` for resources, and `variables.tf` for variable definitions.  
Place them under an `infrastructure` folder.

- **terraform.tf**: Add a provider block including `google` and `google-beta`. Also provision a GCS bucket and configure the backend to use it.  
- **variables.tf**: Define repeatable values as variables for modularity.  
- **main.tf**: Create an Artifact Registry repository resource (for storing your images).

### Step 6: Push Images to Artifact Registry
Now that Artifact Registry is created and the image is built, push it to GCP.

Add two new pipeline stages:
- **Stage 3:** Authenticate to the Artifact Registry using the GCP service account (stored as a Jenkins secret file).  
- **Stage 4:** Push the latest image to your repository with `dockerImage.push`.

### Step 7: Create the Cloud Run Service
Create a Cloud Run v2 service in `main.tf`.  
Expose port 8080 and set your desired min/max instance counts.  
Add an IAM binding to grant the `roles/run.invoker` role to `allUsers` (public access).  
This makes the service publicly accessible via HTTPS.

### Step 8: Terraform Build Stage
Add a Jenkins stage to build and apply all resources defined in `main.tf`.

Example commands:
- `terraform fmt` : formats the Terraform files  
- `terraform init` : initializes providers and backends  
- `terraform plan` : previews the infrastructure changes  
- `terraform apply -auto-approve` : applies and provisions resources

### Step 9: Load Balancer Configuration
To use a custom domain with your Cloud Run service, create a global HTTPS load balancer in `main.tf`.

Provision the following resources:
- `google_compute_global_address` : Global static IPv4 address for the load balancer frontend  
- `google_compute_region_network_endpoint_group` : Serverless NEG referencing the Cloud Run service  
- `google_compute_managed_ssl_certificate` : Google-managed SSL certificate for HTTPS  
- `google_compute_backend_service` – Backend definition pointing to the serverless NEG  
- `google_compute_url_map` : Routing rules (default route points to the backend service)  
- `google_compute_target_https_proxy` : Handles HTTPS termination and connects to the URL map  
- `google_compute_global_forwarding_rule` : Routes incoming traffic on port 443 to the HTTPS proxy

### Step 10: Update DNS
After provisioning the load balancer, create an **A record** wherever your domain is hosted.  
Point it to the external IP of your load balancer.  
Once the SSL certificate status is **ACTIVE**, your app should be accessible via your custom domain.

### Step 11: Deploy New Revisions
To deploy new revisions, your Jenkins pipeline can call `gcloud run deploy` after pushing a new image.  
This updates all running containers with the latest version without downtime.  
For production environments, you could extend this with canary or blue-green deployment strategies.

### Step 12: Intro to Cloud Armor
Finally, we can strengthen our security by adding Cloud Armor.  
Create a `google_compute_security_policy` and attach it to your backend service.  
Then create one or more `google_compute_security_policy_rule` blocks for specific protections.

I'm going to use a throttling policy to limit requests per IP or rate-limit heavy asset downloads.  
Cloud Armor can also enforce geo restrictions or apply Google’s preconfigured OWASP rulesets for web protection.

---

## Final Outcome
- Unity WebGL app is hosted on Cloud Run behind a global HTTPS load balancer.  
- Custom domain secured with a Google-managed SSL certificate.  
- Cloud Armor provides rate-limiting and security protection.  
- Jenkins automates build, push, and deploy workflows.  
- Terraform manages all GCP resources and infrastructure state remotely.

---

## Author
**Brennan Vincent**  [Resume](https://resume.brennanjvincent.com)
Cloud & Infrastructure Engineer | Unity Developer | DevOps Enthusiast
