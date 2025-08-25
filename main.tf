# Copyright Amazon.com, Inc. or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

module "packaging" {
  source = "./modules/aft-archives"
}

module "aft_account_provisioning_framework" {
  providers = {
    aws = aws.aft_management
  }
  source                                           = "./modules/aft-account-provisioning-framework"
  aft_account_provisioning_framework_sfn_name      = local.aft_account_provisioning_framework_sfn_name
  aft_account_provisioning_customizations_sfn_name = local.aft_account_provisioning_customizations_sfn_name
  trigger_customizations_sfn_name                  = local.trigger_customizations_sfn_name
  aft_features_sfn_name                            = local.aft_features_sfn_name
  aft_sns_topic_arn                                = module.aft_account_request_framework.aft_sns_topic_arn
  aft_failure_sns_topic_arn                        = module.aft_account_request_framework.aft_failure_sns_topic_arn
  aft_common_layer_arn                             = module.aft_lambda_layer.layer_version_arn
  aft_kms_key_arn                                  = module.aft_account_request_framework.aft_kms_key_arn
  aft_enable_vpc                                   = module.aft_account_request_framework.vpc_deployment
  aft_vpc_private_subnets                          = module.aft_account_request_framework.aft_vpc_private_subnets
  aft_vpc_default_sg                               = module.aft_account_request_framework.aft_vpc_default_sg
  cloudwatch_log_group_retention                   = var.cloudwatch_log_group_retention
  provisioning_framework_archive_path              = module.packaging.provisioning_framework_archive_path
  provisioning_framework_archive_hash              = module.packaging.provisioning_framework_archive_hash
  create_role_lambda_function_name                 = local.create_role_lambda_function_name
  tag_account_lambda_function_name                 = local.tag_account_lambda_function_name
  persist_metadata_lambda_function_name            = local.persist_metadata_lambda_function_name
  account_metadata_ssm_lambda_function_name        = local.account_metadata_ssm_lambda_function_name
  delete_default_vpc_lambda_function_name          = local.delete_default_vpc_lambda_function_name
  enroll_support_lambda_function_name              = local.enroll_support_lambda_function_name
  enable_cloudtrail_lambda_function_name           = local.enable_cloudtrail_lambda_function_name
  lambda_runtime_python_version                    = local.lambda_runtime_python_version
  sns_topic_enable_cmk_encryption         = var.sns_topic_enable_cmk_encryption
  cloudwatch_log_group_enable_cmk_encryption = var.cloudwatch_log_group_enable_cmk_encryption
}

module "aft_account_request_framework" {
  providers = {
    aws               = aws.aft_management
    aws.ct_management = aws.ct_management
  }
  source                                      = "./modules/aft-account-request-framework"
  account_factory_product_name                = local.account_factory_product_name
  aft_account_provisioning_framework_sfn_name = local.aft_account_provisioning_framework_sfn_name
  aft_common_layer_arn                        = module.aft_lambda_layer.layer_version_arn
  cloudwatch_log_group_retention              = var.cloudwatch_log_group_retention
  aft_enable_vpc                              = var.aft_enable_vpc
  aft_vpc_cidr                                = var.aft_vpc_cidr
  aft_vpc_private_subnet_01_cidr              = var.aft_vpc_private_subnet_01_cidr
  aft_vpc_private_subnet_02_cidr              = var.aft_vpc_private_subnet_02_cidr
  aft_vpc_public_subnet_01_cidr               = var.aft_vpc_public_subnet_01_cidr
  aft_vpc_public_subnet_02_cidr               = var.aft_vpc_public_subnet_02_cidr
  aft_vpc_endpoints                           = var.aft_vpc_endpoints
  concurrent_account_factory_actions          = var.concurrent_account_factory_actions
  request_framework_archive_path              = module.packaging.request_framework_archive_path
  request_framework_archive_hash              = module.packaging.request_framework_archive_hash
  lambda_runtime_python_version               = local.lambda_runtime_python_version
  backup_recovery_point_retention             = var.backup_recovery_point_retention
  aft_customer_vpc_id                         = var.aft_customer_vpc_id
  aft_customer_private_subnets                = var.aft_customer_private_subnets

  # 👇 Required new arguments
  cloudwatch_log_group_enable_cmk_encryption  = var.cloudwatch_log_group_enable_cmk_encryption
  sns_topic_enable_cmk_encryption             = var.sns_topic_enable_cmk_encryption
}


module "aft_backend" {
  providers = {
    aws.primary_region   = aws.aft_management
    aws.secondary_region = aws.tf_backend_secondary_region
  }
  source                                                = "./modules/aft-backend"
  primary_region                                        = var.ct_home_region
  secondary_region                                      = var.tf_backend_secondary_region
  aft_management_account_id                             = var.aft_management_account_id
  aft_backend_bucket_access_logs_object_expiration_days = var.aft_backend_bucket_access_logs_object_expiration_days
}

module "aft_code_repositories" {
  providers = {
    aws = aws.aft_management
  }
  source = "./modules/aft-code-repositories"

  vpc_id                        = module.aft_account_request_framework.aft_vpc_id
  aft_config_backend_bucket_id  = module.aft_backend.bucket_id
  aft_config_backend_table_id   = module.aft_backend.table_id
  aft_config_backend_kms_key_id = module.aft_backend.kms_key_id
  account_request_table_name    = module.aft_account_request_framework.request_table_name
  codepipeline_s3_bucket_arn    = module.aft_customizations.aft_codepipeline_customizations_bucket_arn
  codepipeline_s3_bucket_name   = module.aft_customizations.aft_codepipeline_customizations_bucket_name
  security_group_ids            = module.aft_account_request_framework.aft_vpc_default_sg
  subnet_ids                    = module.aft_account_request_framework.aft_vpc_private_subnets

  # 👇 required arguments (match your variables.tf)
  aft_kms_key_arn                            = module.aft_account_request_framework.aft_kms_key_arn
  cloudwatch_log_group_retention             = var.cloudwatch_log_group_retention
  cloudwatch_log_group_enable_cmk_encryption = var.cloudwatch_log_group_enable_cmk_encryption
  codebuild_compute_type                     = var.aft_codebuild_compute_type

  # repos
  account_request_repo_branch                     = var.account_request_repo_branch
  account_request_repo_name                       = var.account_request_repo_name
  account_customizations_repo_name                = var.account_customizations_repo_name
  global_customizations_repo_name                 = var.global_customizations_repo_name
  github_enterprise_url                           = var.github_enterprise_url
  gitlab_selfmanaged_url                          = var.gitlab_selfmanaged_url
  vcs_provider                                    = var.vcs_provider
  terraform_distribution                          = var.terraform_distribution
  account_provisioning_customizations_repo_name   = var.account_provisioning_customizations_repo_name
  account_provisioning_customizations_repo_branch = var.account_provisioning_customizations_repo_branch
  account_customizations_repo_branch              = var.account_customizations_repo_branch
  global_customizations_repo_branch               = var.global_customizations_repo_branch
  global_codebuild_timeout                        = var.global_codebuild_timeout
  aft_enable_vpc                                  = module.aft_account_request_framework.vpc_deployment
}


module "aft_customizations" {
  providers = {
    aws               = aws.aft_management
    aws.ct_management = aws.ct_management
  }
  source = "./modules/aft-customizations"

  account_request_topic_arn                   = module.aft_account_request_framework.account_request_topic_arn
  aft_common_layer_arn                        = module.aft_lambda_layer.layer_version_arn
  customizations_archive_path                 = module.packaging.customizations_archive_path
  customizations_archive_hash                 = module.packaging.customizations_archive_hash
  lambda_runtime_python_version               = local.lambda_runtime_python_version
  terraform_distribution                      = var.terraform_distribution
  terraform_version                           = var.terraform_version
  tf_cloud_organization                       = var.tf_cloud_organization
  tf_cloud_token                              = var.tf_cloud_token
  tf_cloud_user_token                         = var.tf_cloud_user_token
  tf_cloud_team_token                         = var.tf_cloud_team_token
  tf_backend_cloud                            = var.tf_backend_cloud
  tf_backend_s3                               = var.tf_backend_s3
  tf_backend_ssm                              = var.tf_backend_ssm
  tf_backend_dynamodb                         = var.tf_backend_dynamodb
  tf_backend_custom                           = var.tf_backend_custom
  backup_recovery_point_retention             = var.backup_recovery_point_retention

  # 👇 Newly required arguments
  codebuild_compute_type                      = var.codebuild_compute_type
  cloudwatch_log_group_enable_cmk_encryption  = var.cloudwatch_log_group_enable_cmk_encryption
  sns_topic_enable_cmk_encryption             = var.sns_topic_enable_cmk_encryption
}
