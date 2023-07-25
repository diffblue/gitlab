# Security Policy Project for Target Group

This project is automatically generated to manage security policies for the project.

The Security Policies Project is a repository used to store policies. All security policies are stored as a YAML file named `.gitlab/security-policies/policy.yml`, with this format:

```yaml
---
scan_execution_policy:
- name: Enforce DAST in every pipeline
  description: This policy enforces pipeline configuration to have a job with DAST scan
  enabled: true
  rules:
  - type: pipeline
    branches:
    - master
  actions:
  - scan: dast
    scanner_profile: Scanner Profile A
    site_profile: Site Profile B
- name: Enforce DAST in every pipeline in the main branch
  description: This policy enforces pipeline configuration to have a job with DAST scan for the main branch
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: dast
    scanner_profile: Scanner Profile C
    site_profile: Site Profile D
```

You can read more about the format and policies schema in the [documentation](http://localhost/help/user/application_security/policies/scan-execution-policies#scan-execution-policy-schema).

## Default branch protection settings

This project is preconfigured with the default branch set as a protected branch, and only maintainers/owners of
[Target Group](http://localhost/groups/target-group) have permission to merge into that branch. This overrides any default branch protection both at the
[group level](http://localhost/help/user/group/manage#change-the-default-branch-protection-of-a-group) and at the
[instance level](http://localhost/help/user/project/repository/branches/default#instance-level-default-branch-protection).
