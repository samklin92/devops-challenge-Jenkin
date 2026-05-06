terraform {
  backend "s3" {
    bucket         = "devops-challenge-tfstate-109804294707"
    key            = "devops-challenge/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "devops-challenge-tflock"
    encrypt        = true
  }
}
