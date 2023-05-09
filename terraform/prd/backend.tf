terraform {
  backend "s3" {
    bucket       = "<redacted>"
    key          = "<redacted>"
    region       = "<redacted>"
    session_name = "<redacted>"
  }
}
