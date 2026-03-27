# Making Docker Image Name and Tag Dynamic Based on Jenkins Build Number

This document explains how to make the Docker image name and tag dynamic using the Jenkins `BUILD_NUMBER` environment variable. This ensures each build produces a unique image tag, which is useful for versioning and deployment.

## Current Setup

- **Jenkinsfile (jenkinfile2)**: Builds a Docker image with a static tag `pythonapp:v1`.
- **docker-compose.yaml**: Uses a static image name `stackdemo` (note: this seems inconsistent with the Jenkinsfile).

## Required Updates

### 1. Update Jenkinsfile (jenkinfile2)

Modify the Docker build step to use the `BUILD_NUMBER` for the tag:

```groovy
stage('Docker-Build') {
    steps {
        echo "Docker Build Step here..."
        sh "docker build . -t pythonapp:${BUILD_NUMBER}"
    }
}
```

**File to edit**: `jenkinfile2`

**Change**: Replace `sh "docker build . -t pythonapp:v1"` with `sh "docker build . -t pythonapp:${BUILD_NUMBER}"`

### 2. Update docker-compose.yaml

Update the image name to match the dynamically built image:

```yaml
version: '3'

services:
  web:
    image: pythonapp:${BUILD_NUMBER}
    build: .
    ports:
      - "9010:8000"
  redis:
    image: redis:alpine
```

**File to edit**: `docker-compose.yaml`

**Change**: Replace `image: stackdemo` with `image: pythonapp:${BUILD_NUMBER}`

**Note**: Since `BUILD_NUMBER` is a Jenkins environment variable, this will only work within the Jenkins pipeline context. If running docker-compose outside of Jenkins, you may need to pass the build number as an environment variable or use a different approach.

## 3. Update Kubernetes Deployment Files (py-redis-configmap/)

For Kubernetes deployments, the image tag in the deployment manifest needs to be updated to use the dynamic build number.

### Update py-deploy.yaml

Modify the image field to use the `BUILD_NUMBER`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: py-deploy-cm
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: python-app-cm
  template:
    metadata:
      labels:
        app: python-app-cm
    spec:
      containers:
        - name: python-container-cm
          image: vishwacloudlab/pythonapp:${BUILD_NUMBER}
          ports:
            - containerPort: 8000
          envFrom:
            - configMapRef:
                name: py-config
          resources:
            requests:
              cpu: "100m"
```

**File to edit**: `py-redis-configmap/py-deploy.yaml`

**Change**: Replace `image: vishwacloudlab/pythonapp:v4-var` with `image: vishwacloudlab/pythonapp:${BUILD_NUMBER}`

**Note**: Since Kubernetes YAML files don't directly support Jenkins environment variables, you'll need to use a tool like `sed` or `envsubst` in your Jenkins pipeline to replace `${BUILD_NUMBER}` with the actual value before applying the manifest. For example:

```groovy
stage('Deploy to Kubernetes') {
    steps {
        sh "sed -i 's/\${BUILD_NUMBER}/${BUILD_NUMBER}/g' py-redis-configmap/py-deploy.yaml"
        sh "kubectl apply -f py-redis-configmap/"
    }
}
```

### Other Files

- **py-service.yaml**: No changes needed (service definition)
- **redis-deploy.yaml**: No changes needed (Redis deployment)
- **redis-service.yaml**: No changes needed (Redis service)
- **configmap.yaml**: No changes needed (configuration data)
- **Jenkinsfile-main**: May need updates if it references the image tag, but check its contents for any static references

## Additional Considerations

- Ensure that the Jenkins pipeline has access to the `BUILD_NUMBER` variable (it's available by default in Jenkins pipelines).
- If you need to use the image in other parts of the pipeline or for deployment, you can reference it as `pythonapp:${BUILD_NUMBER}`.
- For production deployments, consider using a registry (e.g., ECR, Docker Hub) and pushing the image with the dynamic tag.
- If you want to clean up old images, you can add a step to remove unused images after deployment.

## Jenkins Environment Variables for Best Practices

To follow best practices and make the pipeline more configurable and maintainable, define environment variables in your Jenkins pipeline for the image name, container registry, and other related settings. This allows easy changes without modifying the pipeline code.

### Define Environment Variables

At the top of your Jenkinsfile (e.g., `jenkinfile2`), add an `environment` block:

```groovy
pipeline {
    agent { label 'docker' }
    
    environment {
        REGISTRY = 'your-registry.com'  // e.g., '123456789.dkr.ecr.us-east-1.amazonaws.com' for ECR
        IMAGE_NAME = 'pythonapp'
        TAG = "${BUILD_NUMBER}"
        FULL_IMAGE_NAME = "${REGISTRY}/${IMAGE_NAME}:${TAG}"
    }
    
    triggers {
        pollSCM('H/2 * * * *')   // every 2 minutes
    }
    
    stages {
        // ... existing stages ...
    }
}
```

### Update Docker Build Stage

Modify the Docker build and push stages to use the environment variables:

```groovy
stage('Docker-Build') {
    steps {
        echo "Docker Build Step here..."
        sh "docker build . -t ${FULL_IMAGE_NAME}"
    }
}

stage('Docker-Push') {
    steps {
        echo "Pushing Docker image..."
        sh "docker push ${FULL_IMAGE_NAME}"
    }
}
```

### Update docker-compose.yaml

Use the full image name in docker-compose:

```yaml
version: '3'

services:
  web:
    image: ${FULL_IMAGE_NAME}
    ports:
      - "9010:8000"
  redis:
    image: redis:alpine
```

**Note**: For docker-compose to work with environment variables, you may need to use `envsubst` or similar tools in your Jenkins pipeline:

```groovy
stage('DockerContainer Creation') {
    steps {
        echo "Running Docker Compose here..."
        sh "envsubst < docker-compose.yaml | docker-compose -f - up -d"
    }
}
```

### Update Kubernetes Deployment

In `py-deploy.yaml`, use the full image name:

```yaml
containers:
  - name: python-container-cm
    image: ${FULL_IMAGE_NAME}
```

And in the Jenkins pipeline, update the sed command:

```groovy
stage('Deploy to Kubernetes') {
    steps {
        sh "sed -i 's|\${FULL_IMAGE_NAME}|${FULL_IMAGE_NAME}|g' py-redis-configmap/py-deploy.yaml"
        sh "kubectl apply -f py-redis-configmap/"
    }
}
```

### Additional Best Practice Environment Variables

Consider adding these environment variables for better pipeline management:

```groovy
environment {
    REGISTRY = 'your-registry.com'
    IMAGE_NAME = 'pythonapp'
    TAG = "${BUILD_NUMBER}"
    FULL_IMAGE_NAME = "${REGISTRY}/${IMAGE_NAME}:${TAG}"
    NAMESPACE = 'default'  // Kubernetes namespace
    DOCKER_CREDENTIALS_ID = 'docker-registry-creds'  // Jenkins credentials ID
    KUBE_CONFIG_CREDENTIALS_ID = 'kube-config'  // Kubernetes config credentials
}
```

### Registry Authentication

For pushing to a private registry, add authentication:

```groovy
stage('Docker-Push') {
    steps {
        echo "Pushing Docker image..."
        withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS} ${REGISTRY}"
            sh "docker push ${FULL_IMAGE_NAME}"
        }
    }
}
```

### Benefits of This Approach

- **Configurability**: Easily change registry, image name, or other settings without code changes
- **Security**: Store sensitive information (like registry credentials) in Jenkins credentials
- **Reusability**: Use the same variables across multiple stages
- **Environment-specific**: Different environments (dev, staging, prod) can have different variable values
- **Maintainability**: Centralized configuration makes updates easier

## Example Usage

After these changes, each Jenkins build will:

1. Build an image with a full name like `your-registry.com/pythonapp:1`
2. Push it to the registry
3. Deploy using the same tagged image in both docker-compose and Kubernetes

This allows for better tracking, security, and deployment flexibility across different environments.