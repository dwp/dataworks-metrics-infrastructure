#!/usr/bin/env python3

import boto3
import botocore
import jinja2
import os
import sys
import yaml
import json
import datetime
from dateutil.tz import tzlocal


def main():
    if 'AWS_PROFILE' in os.environ:
        boto3.setup_default_session(profile_name=os.environ['AWS_PROFILE'])
    if 'AWS_PROFILE_MGT_DEV' in os.environ:
        secrets_session = boto3.Session(
            profile_name=os.environ['AWS_PROFILE_MGT_DEV'])
    elif 'AWS_SECRETS_ROLE' in os.environ:
        secrets_session = assumed_role_session(os.environ['AWS_SECRETS_ROLE'])
    if 'AWS_REGION' in os.environ:
        ssm = boto3.client('ssm', region_name=os.environ['AWS_REGION'])
        secrets_manager = secrets_session.client(
            'secretsmanager', region_name=os.environ['AWS_REGION'])
    else:
        ssm = boto3.client('ssm')
        secrets_manager = secrets_session.client('secretsmanager')

    try:
        parameter = ssm.get_parameter(
            Name='terraform_bootstrap_config', WithDecryption=False)
        monitoring_secret = secrets_manager.get_secret_value(
            SecretId="/concourse/dataworks/monitoring")
        dataworks_secret = secrets_manager.get_secret_value(
            SecretId="/concourse/dataworks/dataworks-secrets")
    except botocore.exceptions.ClientError as e:
        error_message = e.response["Error"]["Message"]
        if "The security token included in the request is invalid" in error_message:
            print("ERROR: Invalid security token used when calling AWS SSM or Secrets Manager. Have you run `aws-sts` recently?")
        else:
            print("ERROR: Problem calling AWS SSM or Secrets Manager: {}".format(
                error_message))
        sys.exit(1)

    config_data = yaml.load(
        parameter['Parameter']['Value'], Loader=yaml.FullLoader)
    config_data['roles'] = json.loads(monitoring_secret['SecretBinary'])[
        os.getenv('TF_WORKSPACE', 'development')]
    config_data['ports'] = json.loads(
        monitoring_secret['SecretBinary'])["ports"]
    config_data['monitoring_dns_zone_ids'] = json.loads(
        monitoring_secret['SecretBinary'])["monitoring_dns_zone_ids"]
    config_data['sdx_dns_zone_ids'] = json.loads(
        monitoring_secret['SecretBinary'])["sdx_dns_zone_ids"]
    config_data['pdm_dns_zone_ids'] = json.loads(
        monitoring_secret['SecretBinary'])["pdm_dns_zone_ids"]

    with open('modules/vpc/vpc.tf.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('modules/vpc/vpc.tf', 'w+') as vpc_tf:
        vpc_tf.write(template.render(config_data))
    with open('modules/vpc/outputs.tf.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('modules/vpc/outputs.tf', 'w+') as vpc_tf:
        vpc_tf.write(template.render(config_data))
    with open('terraform.tf.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('terraform.tf', 'w+') as terraform_tf:
        terraform_tf.write(template.render(config_data))
    with open('terraform.tfvars.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('terraform.tfvars', 'w+') as terraform_tfvars:
        terraform_tfvars.write(template.render(config_data))
    print("Terraform config successfully created")


def assumed_role_session(role_arn: str, base_session: botocore.session.Session = None):
    base_session = base_session or boto3.session.Session()._session
    fetcher = botocore.credentials.AssumeRoleCredentialFetcher(
        client_creator=base_session.create_client,
        source_credentials=base_session.get_credentials(),
        role_arn=role_arn,
        extra_args={
            #    'RoleSessionName': None # set this if you want something non-default
        }
    )
    creds = botocore.credentials.DeferredRefreshableCredentials(
        method='assume-role',
        refresh_using=fetcher.fetch_credentials,
        time_fetcher=lambda: datetime.datetime.now(tzlocal())
    )
    botocore_session = botocore.session.Session()
    botocore_session._credentials = creds
    return boto3.Session(botocore_session=botocore_session)


if __name__ == "__main__":
    main()

