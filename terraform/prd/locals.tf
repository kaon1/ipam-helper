/* locals.tf
Put your local variables here.
*/

// Unique name for uniqueness.

resource "random_pet" "gen_name" {
  keepers = {
    ts = "2023-02-14"
  }
}

// Locals

locals {
  common_tags = {
    "Repository" = "<redacted>"
    "Terraform"  = "true"
    "gen"        = random_pet.gen_name.id
  }
}
