# bigquery-cost-control

Run a google cloud function every 10 mins to check if the daily BigQuery spend of a given project (in dollars)
passes a certain threshold. If the threshold is passed, send a slack notification alert.


The terraform script specifies a configuration for Cloud Scheduler to invoke the Cloud Function every 10 minutes. 


### Environment variables:
- project
- region
- SLACK_WEBHOOK_URL
- THRESHOLD  # The minimum value in dollars that the daily spend needs to surpass for an alert to be triggered.
