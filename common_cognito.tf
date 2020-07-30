resource "aws_cognito_user_pool_client" "grafana" {
  count                                = local.is_management_env ? 1 : 0
  name                                 = "grafana"
  user_pool_id                         = data.terraform_remote_state.aws_concourse.outputs.cognito.user_pool_id
  generate_secret                      = true
  callback_urls                        = ["https://${aws_route53_record.grafana_loadbalancer[0].fqdn}/login/generic_oauth"]
  logout_urls                          = ["https://${aws_route53_record.grafana_loadbalancer[0].fqdn}"]
  explicit_auth_flows                  = ["ALLOW_CUSTOM_AUTH", "ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["phone", "aws.cognito.signin.user.admin", "email", "openid", "profile"]
  supported_identity_providers         = ["COGNITO"]
}

resource "aws_cognito_user_group" "grafana_editor" {
  count        = local.is_management_env ? 1 : 0
  name         = "grafana-editor"
  user_pool_id = data.terraform_remote_state.aws_concourse.outputs.cognito.user_pool_id
  description  = "Grafana Editors"
}
