# ARO Migration Hackathon Guide

## Overview

Welcome to the Azure Red Hat OpenShift (ARO) Migration Hackathon! 

In this challenge, you'll be migrating an "on-premises" application to ARO while implementing modern DevOps practices using GitHub. The goal is to modernize the application deployment, enhance security, and improve the overall development workflow.

## Prerequisites

Before starting, ensure you have:

1. **Azure Account** with permissions to create resources
2. **GitHub Account** 
3. **Docker Desktop** installed locally
4. **Azure CLI** installed
5. **Visual Studio Code** or your preferred IDE
6. **Git** installed

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/microsoft/aro-migration-hackathon.git
cd aro-migration-hackathon
```

### 2. Set Up Azure Resources

We've provided an interactive script that will create all the necessary Azure resources for the hackathon:

```bash
# Make the script executable
chmod +x ./scripts/setup-azure-resources.sh

# Run the setup script
./scripts/setup-azure-resources.sh
```

This script will:
- Create a Resource Group
- Set up networking components
- Create an Azure Container Registry
- Optionally create an ARO cluster (or provide instructions for later creation)
- Save all configuration details to a `.env` file

## Understanding the Application

### 1. Application Architecture

The Task Manager application consists of:
- **Frontend**: React-based web UI
- **Backend API**: Node.js/Express 
- **Database**: MongoDB

### 2. Running Locally with Docker Compose
#### Understanding Docker Compose

Docker Compose is a tool for defining and running multi-container Docker applications. It uses a YAML file to configure your application's services and allows you to start all services with a single command.

#### Application Architecture

Our Task Manager application consists of three main components:

1. **Frontend**: React-based web UI served via Nginx
2. **Backend API**: Node.js/Express REST API
3. **Database**: MongoDB for data storage
4. **MongoDB Express**: Web-based MongoDB admin interface

```bash
cd on-prem-app/deployment
docker-compose up
```

Once the application is running, you can access:
- **Frontend**: http://localhost
- **Backend API**: http://localhost:3001/api/tasks
- **MongoDB Express**: http://localhost:8081

### 3. Exploring the Database

1. Open MongoDB Express at http://localhost:8081
2. Navigate through the interface to:
   - View the database structure
   - Create sample tasks
   - Modify existing data
   - Observe how changes affect the application

### 4. Testing the API

You can use tools like cURL, Postman, or your browser to test the API:

```bash
# Get all tasks
curl http://localhost:3001/api/tasks

# Create a new task
curl -X POST http://localhost:3001/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"New Task","description":"Task description","status":"pending"}'

# Update a task (replace TASK_ID with actual ID)
curl -X PUT http://localhost:3001/api/tasks/TASK_ID \
  -H "Content-Type: application/json" \
  -d '{"status":"completed"}'

# Delete a task (replace TASK_ID with actual ID)
curl -X DELETE http://localhost:3001/api/tasks/TASK_ID
```

## Hackathon Challenges

Your team will need to complete the following challenges:

### Challenge 1: Containerization and ARO Deployment

1. **Build and push the container images** to your Azure Container Registry
2. **Deploy the application** to your ARO cluster using the provided Kubernetes manifests
3. **Configure routes** to expose the application externally
4. **Verify the deployment** and ensure it's working correctly

### Challenge 2: GitHub CI/CD Pipeline

1. **Fork the repository** to your GitHub account
2. **Set up GitHub Actions** for continuous integration and deployment
3. **Configure GitHub Secrets** for secure pipeline execution
4. **Implement automated testing** in the pipeline
5. **Create a workflow** that deploys to ARO when changes are pushed to main

#### Setting up CI/CD for ARO Deployment

Your CI/CD pipeline should handle the entire process from building your application to deploying it on your ARO cluster:

**Required GitHub Secrets:**
- `REGISTRY_URL`: The URL of your Azure Container Registry (e.g., myregistry.azurecr.io)
- `REGISTRY_USERNAME`: Username for your container registry (usually the registry name)
- `REGISTRY_PASSWORD`: Password or access key for your container registry
- `OPENSHIFT_SERVER`: The API server URL of your ARO cluster
- `OPENSHIFT_TOKEN`: Authentication token for your ARO cluster

**Pipeline Structure:**
- **Build Stage**: Compile code, run tests, and build container images
- **Push Stage**: Push images to your container registry with proper tags
- **Deploy Stage**: Deploy the application to your ARO cluster using OpenShift CLI

**Advanced Deployment Options:**
- Consider setting up multiple environments (dev, staging, production)
- Implement Blue/Green deployment for zero-downtime updates
- Add post-deployment health checks to verify successful deployment

**Best Practices:**
- Tag images with both the commit SHA and semantic version
- Implement automated rollback if deployment health checks fail
- Use GitHub environments to require approvals for production deployments
- Run security scanning on your container images before deployment

### Challenge 3: GitHub Copilot Integration

1. **Enable GitHub Copilot** in your development environment
2. **Use Copilot to add a new feature** to the application. Some ideas:
   - Task search functionality
   - Task categories or tags
   - Due date reminders
   - User authentication
3. **Document how Copilot assisted** in the development process

### Challenge 4: GitHub AI Models

1. **Use GitHub AI Models** to:
   - Generate documentation for your code
   - Create useful comments
   - Explain complex sections of the codebase
   - Suggest optimizations or improvements
2. **Compare the suggestions** against the original code
3. **Implement at least one improvement** suggested by the AI

### Challenge 5: GitHub Advanced Security

1. **Enable GitHub Advanced Security** features:
   - Code scanning with CodeQL
   - Dependency scanning
   - Secret scanning
2. **Add security scanning** to your CI/CD pipeline
3. **Address any security issues** identified by the scans
4. **Implement dependency management** best practices

### Challenge 6: Monitoring and Observability

1. **Set up basic monitoring** for your application in ARO
2. **Implement logging** and configure log aggregation
3. **Create at least one dashboard** to visualize application performance
4. **Configure alerts** for critical metrics

## Resources

- [Azure Red Hat OpenShift Documentation](https://learn.microsoft.com/en-us/azure/openshift/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [GitHub Advanced Security](https://docs.github.com/en/get-started/learning-about-github/about-github-advanced-security)
- [OpenShift Developer Documentation](https://docs.openshift.com/container-platform/4.10/welcome/index.html)

## Getting Help

If you encounter issues during the hackathon, please reach out to the mentors who will be available to assist you.

Good luck and happy hacking!