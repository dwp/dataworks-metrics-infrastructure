# Labeling

Labels are the preferred and more powerful way to filter targets when scraping.  The labels we should focus on using are tags, as that is something we are 100% in control of.

Something as simple as:
```
  - source_labels: [__meta_ec2_tag_Name]
    separator: ;
    regex: Brian
    replacement: $1
    action: keep
```

Will drop targets for which regex does not match `Brian` as the tag value of tag key `Name`

Some labels can be difficult to translate, and you can query the Prometheus API to return all known targets and their associated labels using from inside the Prometheus container:

`curl http://localhost:9090/api/v1/targets | cat >> targets`

Then search inside `targets` for the tag you wish to use as a label.  For instance the tag key of `aws:elasticmapreduce:instance-group-role` is formed as `__meta_ec2_tag_aws_elasticmapreduce_instance_group_role` in Prometheus.

Using the above label allows us to filter against EMR instances, as they are the only instances with such a tag key.
