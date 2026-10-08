terraform {
  backend "s3" {
    bucket       = "platform-capstone-terraform-state-911167903075"
    key          = "platform-capstone/prod/terraform.tfstate"
    region       = "eu-west-1"
    use_lockfile = true
  }
}
