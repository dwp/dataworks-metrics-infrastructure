#!/usr/bin/env python3

import boto3
import botocore
import jinja2
import os
import sys
import yaml


def main():
    if 'AWS_PROFILE' in os.environ:
        boto3.setup_default_session(profile_name=os.environ['AWS_PROFILE'])
    if 'AWS_REGION' in os.environ:
        ssm = boto3.client('ssm', region_name=os.environ['AWS_REGION'])
    else:
        ssm = boto3.client('ssm')

    try:
        parameter = ssm.get_parameter(
            Name='terraform_bootstrap_config', WithDecryption=False)
    except botocore.exceptions.ClientError as e:
        error_message = e.response["Error"]["Message"]
        if "The security token included in the request is invalid" in error_message:
            print(
                "ERROR: Invalid security token used when calling AWS SSM. Have you run `aws-sts` recently?")
        else:
            print("ERROR: Problem calling AWS SSM: {}".format(error_message))
        sys.exit(1)

    config_data = yaml.load(
        parameter['Parameter']['Value'], Loader=yaml.FullLoader)
    with open('ci/jobs/dev.yml.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('ci/jobs/dev.yml', 'w+') as pipeline:
        pipeline.write(template.render(config_data))
    with open('ci/jobs/qa.yml.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('ci/jobs/qa.yml', 'w+') as pipeline:
        pipeline.write(template.render(config_data))
    with open('ci/jobs/integration.yml.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('ci/jobs/integration.yml', 'w+') as pipeline:
        pipeline.write(template.render(config_data))
    with open('ci/jobs/preprod.yml.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('ci/jobs/preprod.yml', 'w+') as pipeline:
        pipeline.write(template.render(config_data))
    with open('ci/jobs/production.yml.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('ci/jobs/production.yml', 'w+') as pipeline:
        pipeline.write(template.render(config_data))
    with open('ci/jobs/management_dev.yml.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('ci/jobs/management_dev.yml', 'w+') as pipeline:
        pipeline.write(template.render(config_data))
    with open('ci/jobs/management.yml.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('ci/jobs/management.yml', 'w+') as pipeline:
        pipeline.write(template.render(config_data))
    with open('ci/jobs/pull_request.yml.j2') as in_template:
        template = jinja2.Template(in_template.read())
    with open('ci/jobs/pull_request.yml', 'w+') as pipeline:
        pipeline.write(template.render(config_data))
    print("Concourse pipeline config successfully created")


if __name__ == "__main__":
    main()
