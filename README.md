# bigquery-cost-control

Run a google cloud function every 10 mins to check if the total_bytes_billed in dollars of a given project 
passes a certain threshold. If the threshold is passed, send a notification alert
