# bigquery-cost-control

Run a google cloud function every 10 mins to check if the daily BigQuery spend of a given project (in dollars)
passes a certain threshold. If the threshold is passed, send a slack notification alert.


The terraform script specifies a configuration for Cloud Scheduler to invoke the Cloud Function every 10 minutes. 


### Environment variables:
- project
- region
- SLACK_WEBHOOK_URL
- THRESHOLD   - _The minimum value in dollars that the daily spend needs to surpass for an alert to be triggered._

You can pass in the environment variables either when running `terraform apply` or have them in a `terraform.tfvars` file in the `terraform/` directory. The environment variables will be populated from the `terraform.tfvars` file.  

## Setup Instructions

1. Clone the repository
2. Go into the terraform/ directory
3. Run `terraform init`
4. Run `terraform plan` to look at the execution plan
5. Run `terraform apply` to spin up the infrastructure

__Note__ You can run `terraform destroy` to delete all the resources created by the terraform configuration. 
