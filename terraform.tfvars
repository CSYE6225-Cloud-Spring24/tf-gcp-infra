project_id              = "devv-415008"
region                  = "us-east1"
zone                    = "us-east1-c"
webapp_subnetroute_cidr = "0.0.0.0/0"
autocreatesubnets       = false
deletedefaultroutes     = true
routingmode             = "REGIONAL"
nexthopgateway          = "default-internet-gateway"
vm_name                 = "virtual-machine"
vm_machine_type         = "e2-medium"
vm_image                = "packer-custom-centos8-image"
vm_disk_type            = "pd-balanced"
vm_disk_size_gb         = 100
app_port                = "8080"

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
  }
]
