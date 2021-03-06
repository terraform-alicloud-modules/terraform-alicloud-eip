variable "region" {
  default = "cn-beijing"
}

provider "alicloud" {
  region = var.region
}

data "alicloud_zones" "default" {
  available_resource_creation = "VSwitch"
}

############################################################################################################
# Resource to create VPC, vswitch, security_group which is used as an argument in alicloud_network_interface
############################################################################################################

resource "alicloud_vpc" "default" {
  name       = "vpc-eip-example"
  cidr_block = "172.16.0.0/12"
}

resource "alicloud_vswitch" "default" {
  vpc_id            = alicloud_vpc.default.id
  cidr_block        = "172.16.0.0/21"
  availability_zone = data.alicloud_zones.default.zones.0.id
  name              = "vswitch-eip-example"
}

resource "alicloud_security_group" "default" {
  count  = "1"
  vpc_id = alicloud_vpc.default.id
  name   = "test-network_interface-eip"
}

resource "alicloud_network_interface" "default" {
  security_groups = [alicloud_security_group.default[0].id]
  vswitch_id      = alicloud_vswitch.default.id
}

######################################################################
# eip full parameters associated with associate-with-network-interface
######################################################################

module "associate-with-network-interface" {
  source = "../../modules/associate-with-network-interface"
  region = var.region

  create               = true
  name                 = "eip-NetworkInterface-example"
  bandwidth            = 5
  internet_charge_type = "PayByTraffic"
  instance_charge_type = "PostPaid"
  period               = 1
  tags = {
    Env      = "Private"
    Location = "foo"
  }

  # The number of network interface created its resource. If this parameter is used, `number_of_eips` will be ignored.
  number_of_computed_instances = 1
  computed_instances = [
    {
      instance_ids  = [alicloud_network_interface.default.id]
      instance_type = "NetworkInterface"
      private_ips   = []
    }
  ]

  # Network interface can be found automactically by name_regex, instance_tags and instance_resource_group_id. If these parameter is used, `number_of_eips` will be ignored.
  name_regex = "foo*"
  instance_tags = {
    Create = "tf"
    Env    = "prod"
  }
  instance_resource_group_id = "rs-132452"
}