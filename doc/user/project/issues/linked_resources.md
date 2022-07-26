---
stage: Monitor
group: Respond
info: 
---

# Linked Resources in an incident **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/230852) in GitLab 15.3. [with a flag](../../../administration/feature_flags.md) named `incident_resource_links_widget`. Enabled on GitLab.com. Disabled on self-managed.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `incident_resource_links_widget`.
On GitLab.com, this feature is available.

In order to share information about the incidents,
GitLab allows to add resource links with an incident issue.
You can add Zoom meeting links, Slack channel links, Slack message threads, Google doc links to collaborate, etc.
This is so that your team members can find the important links without going through the long discussion in comments.

## View linked resources of an incident

Linked Resources for an incident are listed under the `Summary` tab.

![Linked resources list](img/linked_resources_list_v15_3.png)

To view the linked resources of an incident:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Monitor > Incidents**.
1. Select an incident.
1. Select the **Summary** tab.

## Create a linked resource

Create a linked resource manually using the form.

Prerequisites:

- You must have at least the Reporter role for the project.

To create a linked resource:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Monitor > Incidents**.
1. Select an incident.
1. Select the plus icon (**{plus-square}**) in the `Linked resources` widget.
1. Complete the required fields.
1. Select **Add**.

## Delete a linked resource

You can also delete a linked resource.

Prerequisities:

- You must have at least the Reporter role for the project.

To delete a linked resource:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Monitor > Incidents**.
1. Select an incident.
1. In the `Linked resources` widget, select the close icon (**{close}**).
