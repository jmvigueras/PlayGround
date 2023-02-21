
// Create FGT cluster config
module "fgt_config" {
  source = "./modules/fgt-config"

  admin_cidr     = local.admin_cidr
  admin_port     = local.admin_port
  rsa-public-key = local.rsa-public-key == null ? trimspace(tls_private_key.ssh.public_key_openssh) : local.rsa-public-key
  api_key        = trimspace(random_string.api_key.result)

  subnet_active_cidrs  = local.fgt_subnet_az1_cidrs
  subnet_passive_cidrs = local.fgt_subnet_az2_cidrs
  fgt-active-ni_ips    = module.fgt_ni-nsg.fgt-active-ni_ips
  fgt-passive-ni_ips   = module.fgt_ni-nsg.fgt-passive-ni_ips

  license_type   = local.fgt_license_type
  license_file_1 = local.fgt_license_file_1
  license_file_2 = local.fgt_license_file_2

  config_fgcp    = true
  vpc-spoke_cidr = local.vpc-spoke_cidr
}

// Create FGT instances
module "fgt" {
  source = "git::github.com/jmvigueras/modules//aws/fgt-ha"

  prefix        = local.prefix
  region        = local.region
  instance_type = local.instance_type
  keypair       = local.keypair_name == null ? aws_key_pair.keypair.key_name : local.keypair_name

  license_type = local.fgt_license_type
  fgt_build    = local.fgt_build

  fgt-active-ni_ids  = module.fgt_ni-nsg.fgt-active-ni_ids
  fgt-passive-ni_ids = module.fgt_ni-nsg.fgt-passive-ni_ids
  fgt_config_1       = module.fgt_config.fgt_config_1
  fgt_config_2       = module.fgt_config.fgt_config_2

  fgt_passive = true
}


// Create FGT interfaces and SG
module "fgt_ni-nsg" {
  source = "git::github.com/jmvigueras/modules//aws/fgt-ha_ni-nsg"

  prefix     = "${local.prefix}-fgt-ni"
  admin_cidr = local.admin_cidr
  admin_port = local.admin_port

  subnet_az1_ids   = local.fgt_subnet_az1_ids
  subnet_az2_ids   = local.fgt_subnet_az2_ids
  subnet_az1_cidrs = local.fgt_subnet_az1_cidrs
  subnet_az2_cidrs = local.fgt_subnet_az2_cidrs

  vpc-sec_id = local.fgt_vpc_id
}

