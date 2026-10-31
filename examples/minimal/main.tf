module "vpc" {
  source = "../../"

  name   = "minimal-vpc"
  region = "fr-par"
  zones  = ["fr-par-1"]

  private_networks = {
    main = {
      name = "minimal-network"
    }
  }
}
