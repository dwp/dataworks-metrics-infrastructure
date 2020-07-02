##################### Grafana Configuration Example #####################

#################################### Paths ####################################
[paths]

#################################### Server ####################################
[server]
domain = ${grafana_domain}
root_url = https://${grafana_domain}

#################################### Database ####################################
[database]

#################################### Cache server #############################
[remote_cache]

#################################### Data proxy ###########################
[dataproxy]

#################################### Analytics ####################################
[analytics]

#################################### Security ####################################
[security]
cookie_secure = true

#################################### Snapshots ###########################
[snapshots]

#################################### Dashboards History ##################
[dashboards]

#################################### Users ###############################
[users]

[auth]

#################################### Anonymous Auth ######################
[auth.anonymous]

#################################### Github Auth ##########################
[auth.github]

#################################### GitLab Auth #########################
[auth.gitlab]

#################################### Google Auth ##########################
[auth.google]

#################################### Grafana.com Auth ####################
[auth.grafana_com]

#################################### Azure AD OAuth #######################
[auth.azuread]

#################################### Okta OAuth #######################
[auth.okta]

#################################### Generic OAuth ##########################
[auth.generic_oauth]
enabled = true
name = OAuth
allow_sign_up = true
client_id = ${client_id}
client_secret = ${client_secret}
scopes = openid profile email
auth_url = https://${cognito_domain}.auth.${region}.amazoncognito.com/oauth2/authorize
token_url = https://${cognito_domain}.auth.${region}.amazoncognito.com/oauth2/token
api_url = https://${cognito_domain}.auth.${region}.amazoncognito.com/oauth2/userinfo

#################################### Basic Auth ##########################
[auth.basic]

#################################### Auth Proxy ##########################
[auth.proxy]

#################################### Auth LDAP ##########################
[auth.ldap]

#################################### SMTP / Emailing ##########################
[smtp]

[emails]

#################################### Logging ##########################
[log]

[log.console]

[log.file]

[log.syslog]

#################################### Usage Quotas ########################
[quota]

#################################### Alerting ############################
[alerting]

#################################### Explore #############################
[explore]

#################################### Internal Grafana Metrics ##########################
[metrics]

[metrics.graphite]

#################################### Grafana.com integration  ##########################
[grafana_com]

#################################### Distributed tracing ############
[tracing.jaeger]

#################################### External image storage ##########################
[external_image_storage]

[external_image_storage.s3]

[rendering]

[panels]

[plugins]

#################################### Grafana Image Renderer Plugin ##########################
[plugin.grafana-image-renderer]

[enterprise]

[feature_toggles]
