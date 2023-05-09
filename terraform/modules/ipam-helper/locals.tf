/* locals.tf
Put your local variables here.
*/

locals {
  svc_name = "${var.app_name}-${var.environment}"
}
