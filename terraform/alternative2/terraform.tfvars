environment       = "dev_2"
region            = "us-east-1"
availability_zone = "us-east-1a"
customer_name     = "interfell_test_2"
tags = {
  environment = "DEV_2"
  project     = "interfell_test_2"
  terraform   = "true"
}

aurora_password = "admin12345"

processor_image = "my-dockerhub-username/my-processor-image:latest"