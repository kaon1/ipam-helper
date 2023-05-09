output "app_name" {
  value = module.ipam-helper.svc_name
}

output "gen_name" {
  value = random_pet.gen_name.id
}
