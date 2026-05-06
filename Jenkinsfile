pipeline {
  agent any

  environment {
    AWS_REGION      = "us-east-1"
    ECR_REPO        = "109804294707.dkr.ecr.us-east-1.amazonaws.com/devops-challenge-app"
    IMAGE_TAG       = "${BUILD_NUMBER}"
    CLUSTER_NAME    = "devops-challenge-cluster"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build') {
      steps {
        sh """
          docker build -t ${ECR_REPO}:${IMAGE_TAG} ./app
          docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REPO}:latest
        """
      }
    }

    stage('Test') {
      steps {
        sh """
          docker run -d -p 3000:3000 --name test-${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
          sleep 5
          curl -f http://localhost:3000/health
          docker stop test-${IMAGE_TAG}
          docker rm test-${IMAGE_TAG}
        """
      }
    }

    stage('Push') {
      steps {
        sh """
          aws ecr get-login-password --region ${AWS_REGION} | \
            docker login --username AWS --password-stdin ${ECR_REPO}
          docker push ${ECR_REPO}:${IMAGE_TAG}
          docker push ${ECR_REPO}:latest
        """
      }
    }

    stage('Deploy') {
      steps {
        sh """
          aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
          kubectl set image deployment/devops-challenge-app app=${ECR_REPO}:${IMAGE_TAG}
          kubectl rollout status deployment/devops-challenge-app
        """
      }
    }
  }

  post {
    success {
      echo "Pipeline succeeded - Build ${IMAGE_TAG} deployed"
    }
    failure {
      echo "Pipeline failed - Build ${IMAGE_TAG}"
      sh """
        docker stop test-${IMAGE_TAG} || true
        docker rm test-${IMAGE_TAG} || true
      """
    }
  }
}
