---
stage: none
group: unassigned
comments: false
description: 'CI/CD data time decay'
---

# CI/CD data time decay

## Summary

GitLab CI/CD is one of the most data and compute intensive components of GitLab.
Since its [initial release in November 2012](https://about.gitlab.com/blog/2012/11/13/continuous-integration-server-from-gitlab/),
the CI/CD subsystem has evolved significantly. It was [integrated into GitLab in September 2015](https://about.gitlab.com/releases/2015/09/22/gitlab-8-0-released/)
and has become [one of the most beloved CI/CD solutions](https://about.gitlab.com/blog/2017/09/27/gitlab-leader-continuous-integration-forrester-wave/).

On February 1st, 2021, a billionth CI/CD build was created and the number of
builds is growing exponentially. We expect to see 20M builds created daily on
GitLab.com in the late of 2024.

GitLab CI/CD has come a long way since the initial release, but the design of
the data storage for pipeline builds remains almost the same since 2012. In
2021 we started working on database decomposition and extracting CI/CD data to
a separate database.

## Goals

**Implement a new architecture of CI/CD data storage to enable scaling.**

## Challenges

There is more than two billion rows describing CI/CD builds in GitLab.com's
database. This data represents a sizeable portion of the whole data stored in
PostgreSQL database running on GitLab.com

This volume contributes to a significant performance problems, development
challenges and is often related to production incidents. It is very difficult
to move this data around, what makes data migration challenging and prevents us
from iterating on architectural initiatives that are supposed to help with
sustaining the increase of demand on GitLab.com

We also expect a [significant growth in the number of builds executed on
GitLab.com](https://docs.gitlab.com/ee/architecture/blueprints/ci_scale/) in
the upcoming years.

## Opportunity

CI/CD data is subject to
[time-decay](https://about.gitlab.com/company/team/structure/working-groups/database-scalability/time-decay.html)
because, usually, pipelines that are a few months old are not frequently
accessed or relevant anymore. Restricting access to processing pipelines that
are longer than a few months might help us to Describe our approach to
partitioning using time-decay pattern.

It is already possible to prevent processing of builds [that have been
archived](/ee/user/admin_area/settings/continuous_integration.html#archive-jobs).
When a build gets archived it will not be possible to retry it, but we do not
remove data from the database.

In order to improve performance and make it easier to scale CI/CD data storage
we might want to:

1. Make it possible to move data out of PostgreSQL to a different data store
   when a build, or a pipeline, gets archived using a retention policy.
1. Make it possible to partition certain database tables, storing CI/CD data,
   using the same retention policy as in the point above.

### Data retention

### Partitioning

### Archived data access

## Iterations

## Status

In progress.

## Who

Proposal:

<!-- vale gitlab.Spelling = NO -->

| Role                         | Who
|------------------------------|-------------------------|
| Author                       | Grzegorz Bizon          |
| Engineering Leader           | Cheryl Li               |
| Product Manager              | Jackie Porter           |

DRIs:

| Role                         | Who
|------------------------------|------------------------|
| Leadership                   | Cheryl Li              |
| Product                      | Jackie Porter          |
| Engineering                  | Grzegorz Bizon         |

Domain experts:

| Area                         | Who
|------------------------------|------------------------|

<!-- vale gitlab.Spelling = YES -->
