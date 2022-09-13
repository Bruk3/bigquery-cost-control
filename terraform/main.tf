provider "google" {
  project = var.project
  region  = var.region
}

# Compress source code
data "archive_file" "src" {
  type        = "zip"
  source_dir  = "${path.root}/../src" # Directory where your Python source code is
  output_path = "${path.root}/../generated/src.zip"
}

# Create a cloud storage bucket for source code to be stored in
resource "google_storage_bucket" "bucket" {
  name = "cost-control-cloud-function" # This bucket name must be unique
  location = "US"
  uniform_bucket_level_access = true

}

# create an archive of the source code and store in bucket
resource "google_storage_bucket_object" "archive" {
  name   = "${data.archive_file.src.output_md5}.zip"
  bucket = google_storage_bucket.bucket.name
  source = "${path.root}/../generated/src.zip"
}

# Enable Cloud Functions API
resource "google_project_service" "cf" {
  project = var.project
  service = "cloudfunctions.googleapis.com"

  disable_dependent_services = true
  disable_on_destroy         = false
}

# Create service account for cloud functions
resource "google_service_account" "sa_bq_user" {
    account_id = "bq-job-creator"
    display_name = "BigQuery Job User Service Account"
}

# Give service account the bigquery.admin role so that it can have permissions to run queries in BigQuery
resource "google_project_iam_member" "bigquery_admin" {
  project = var.project
  role    = "roles/bigquery.admin" # TODO - does not follow minimal permissions best practice
  member  = "serviceAccount:${google_service_account.sa_bq_user.email}"
}

# TODO - Require https and have more fine-grained IAM permissions to restrict invokers 
resource "google_cloudfunctions_function" "function" {
  name        = "bigquery-cost-control-function"
  description = "A cloud function that runs queries against bigquery information schema"
  runtime     = "python37"

  environment_variables = {
    PROJECT_ID = var.project,
    SLACK_WEBHOOK_URL = var.SLACK_WEBHOOK_URL
    THRESHOLD = var.THRESHOLD
  }

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = true
  entry_point           = "main" 
  service_account_email = "${google_service_account.sa_bq_user.email}"
}


# # Create IAM entry so all users can invoke the function
# # TODO - Minimal permissions best practice
# resource "google_cloudfunctions_function_iam_member" "invoker" {
#   project        = google_cloudfunctions_function.function.project
#   region         = google_cloudfunctions_function.function.region
#   cloud_function = google_cloudfunctions_function.function.name

#   role   = "roles/cloudfunctions.invoker"
#   member = "allUsers"
# }

# Create a service account for invoking the cloud function via the cloud scheduler
resource "google_service_account" "service_account" {
  account_id   = "cloud-function-invoker"
  display_name = "Cloud Function Tutorial Invoker Service Account"
}


resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.service_account.email}"
}


resource "google_cloud_scheduler_job" "job" {
  name             = "cost-control-cloud-function-scheduler"
  description      = "Trigger the ${google_cloudfunctions_function.function.name} Cloud Function every 10 mins."
  schedule         = "*/10 * * * *" # Every 10 mins
  time_zone        = "America/New_York"
  attempt_deadline = "320s"

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions_function.function.https_trigger_url

    oidc_token {
      service_account_email = google_service_account.service_account.email
    }
  }
}