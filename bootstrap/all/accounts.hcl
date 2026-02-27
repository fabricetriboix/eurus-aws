locals {
  accounts = {
    common-nonprod = {
      id    = "112233445566"
      type  = "common"
      realm = "nonprod"
    }
    common-prod = {
      id    = "112233445566"
      type  = "common"
      realm = "prod"
    }
    dev = {
      id    = "112233445566"
      type  = "app"
      realm = "nonprod"
    }
    prod = {
      id    = "112233445566"
      type  = "app"
      realm = "prod"
    }
  }
}
