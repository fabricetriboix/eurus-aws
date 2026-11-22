locals {
  accounts = {
    cnp = {
      id    = "112233445566"
      type  = "common"
      realm = "nonprod"
    }
    cp = {
      id    = "112233445566"
      type  = "common"
      realm = "prod"
    }
    dev = {
      id    = "112233445566"
      type  = "app"
      realm = "nonprod"
    }
    stg = {
      id    = "112233445566"
      type  = "app"
      realm = "nonprod"
    }
    prd = {
      id    = "112233445566"
      type  = "app"
      realm = "prod"
    }
  }
}
