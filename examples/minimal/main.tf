module "vpc" {
  source = "../../"

  organization_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  project_name    = "default"

  vpc_name   = "minimal-vpc"
  vpc_region = "fr-par"
  vpc_zones  = ["fr-par-1"]

  network_private_networks = {
    main = {
      name = "minimal-network"
    }
  }
}
