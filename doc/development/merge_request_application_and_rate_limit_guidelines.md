---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

## Application/misuse limits

Every new feature should have safe usage quotas introduced.
The quota should be optimised to a level that we consider the feature to
be performant and usable for the user, but **not limiting**.

**We want the features to be fully usable for the users.**
**However, we want to ensure that the feature continues to perform well if used at its limit**
**and it doesn't cause availability issues.**

Consider that it's always better to start with some kind of limitation,
instead of later introducing a breaking change that would result in some
workflows breaking.

The intent is to provide a safe usage pattern for the feature,
as our implementation decisions are optimised for the given data set.
Our feature limits should reflect the optimisations that we introduced.

The intent of quotas could be different:

1. We want to provide higher quotas for higher tiers of features:
   we want to provide on GitLab.com more capabilities for different tiers,
1. We want to prevent misuse of the feature: someone accidentally creates
   10000 deploy tokens, because of a broken API script,
1. We want to prevent abuse of the feature: someone purposely creates
   a 10000 pipelines to take advantage of the system.