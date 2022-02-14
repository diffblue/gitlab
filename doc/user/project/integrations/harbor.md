---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Harbor Container Registry integration **(FREE)**

Use Harbor as GitLab group or project's container registry.

[Harbor](https://goharbor.io/) is an open source registry that secures artifacts with policies and role-based access control, ensures images are scanned and free from vulnerabilities, and signs images as trusted. Harbor, a CNCF Graduated project, delivers compliance, performance, and interoperability to help you consistently and securely manage artifacts across cloud native compute platforms like Kubernetes and Docker.

Harbor Container Registry integration will be useful to users who have a need for GitLab CI and a container image repository.

## Prerequisites

* In the Harbor instance, the project to be integrated has been created, and the logged-in user needs to have permission to pull, push, and edit images in the Harbor project.

## Configure GitLab

GitLab supports integrating Harbor projects at the group or project level. Complete these steps in GitLab:

1. Go to your group/project and select **Settings > Integrations**.
1. Select **Harbor**.
1. Turn on the **Active** toggle under **Enable Integration**.
1. Provide the Harbor configuration information:
   - **Harbor URL**: The base URL to the Harbor instance which is being linked to this GitLab project. For example, 'https://harbor.example.net'.
   - **Project Name**: The Project name to the Harbor instance. For example, 'testproject'.  
   - **Username**: Username for Harbor instance, which should meet the requirements in  [prerequisites](#prerequisites).
   - **Password**: User password for Harbor instance.

1. Select **Save changes**.

After the Harbor integration is activated:

* Global variables '$HARBOR_USER', '$HARBOR_PASSWORD', '$HARBOR_URL' and '$HARBOR_PROJECT' will be created for CI/CD usage.

* Project-level integration settings override group-level integration settings.
