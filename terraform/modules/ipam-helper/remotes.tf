/* remotes.tf
Retrieves data from the base account terraform state.
*/

data "terraform_remote_state" "account_base" {
  backend = "s3"
  config = {
    region   = "<redacted>"
    bucket   = "<redacted>"
    key      = "<redacted>"
    role_arn = "<redacted>"
  }
}
