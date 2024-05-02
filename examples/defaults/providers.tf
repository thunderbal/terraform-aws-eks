# providers.tf

provider "aws" {
  default_tags {
    tags = {
      Project = "ex-${basename(path.cwd)}"
      Iac     = "terraform"
    }
  }
}
