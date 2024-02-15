project_id              = "csye-6225-414222"
region                  = "us-east1"
zone                    = "us-east1-c"
webapp_subnetroute_cidr = "0.0.0.0/0"
autocreatesubnets       = false
deletedefaultroutes     = true
routingmode             = "REGIONAL"
nexthopgateway          = "default-internet-gateway"
vpcs = [
  {
    name                  = "vpc1"
    vpc_name              = "vpc1"
    websubnet_name        = "webapp"
    dbsubnet_name         = "db"
    webapp_subnet_cidr    = "10.0.1.0/24"
    db_subnet_cidr        = "10.0.2.0/24"
    websubnetroutename    = "webapp-route"
    privateipgoogleaccess = true
  },
  {
    name                  = "vpc2"
    vpc_name              = "vpc2"
    websubnet_name        = "webapp1"
    dbsubnet_name         = "db1"
    webapp_subnet_cidr    = "10.0.3.0/24"
    db_subnet_cidr        = "10.0.4.0/24"
    websubnetroutename    = "webapp1-route"
    privateipgoogleaccess = true
  }
]
