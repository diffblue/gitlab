---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

## Application and Rate Limit Guidelines


GitLab, like most large applications, enforces limits within certain features.
The absences of limits can affect security, performance, data, or could even
exhaust the allocated resources for the application. 

Every new feature should have safe usage limits included in its implementation.
Limits are applicable for system level resource pools (e.g. API requests,  sshd
connections, db connections, storage, etc.) and domain level objects (e.g. CI
minutes, groups, sign in attempts, etc.)
Limits are required if the absence of the limit matches severity 1 - 3 in the [Severity
Definitions for Limit Related
Bugs](https://about.gitlab.com/handbook/engineering/quality/issue-triage/#limit-related-bugs).

### Documentation requirements

* Any additions, removals, or updates to limits must be reflected in the [GitLab application limits](https://docs.gitlab.com/ee/administration/instance_limits.html) documentation.

### Additional Documentation about Implementing Limits

* [Overview of Rate Limits for GitLab.com](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/rate-limiting)


