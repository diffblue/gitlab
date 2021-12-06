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

On February 1st, 2021, GitLab.com surpassed 1 billion CI/CD builds, and the number of
builds [continues to grow exponentially](https://docs.gitlab.com/ee/architecture/blueprints/ci_scale/).

GitLab CI/CD has come a long way since the initial release, but the design of
the data storage for pipeline builds remains almost the same since 2012. In
2021 we started working on database decomposition and extracting CI/CD data to
a separate database.

## Goals

**Implement a new architecture of CI/CD data storage to enable scaling.**

## Challenges

There are more than two billion rows describing CI/CD builds in GitLab.com's
database. This data represents a sizeable portion of the whole data stored in
PostgreSQL database running on GitLab.com.

This volume contributes to significant performance problems, development
challenges and is often related to production incidents.

We also expect a [significant growth in the number of builds executed on
GitLab.com](https://docs.gitlab.com/ee/architecture/blueprints/ci_scale/) in
the upcoming years.

## Opportunity

CI/CD data is subject to
[time-decay](https://about.gitlab.com/company/team/structure/working-groups/database-scalability/time-decay.html)
because, usually, pipelines that are a few months old are not frequently
accessed or are even not relevant anymore. Restricting access to processing
pipelines that are longer than a few months might help us to move this data to
a different storage, that is more performant and cost effective.

It is already possible to prevent processing builds [that have been
archived](/ee/user/admin_area/settings/continuous_integration.html#archive-jobs).
When a build gets archived it will not be possible to retry it, but we do not
move data from the database.

In order to improve performance and make it easier to scale CI/CD data storage
we might want to follow these three tracks described below.

### Move rarely accessed data

Once a build (or a pipeline) gets archived, it is no longer possible to resume
pipeline processing in such pipeline. It means that all the metadata, we store
in PostgreSQL, that is needed to efficiently and reliably process builds can be
safely moved to a different data store.

Currently, storing pipeline processing data is expensive as this kind of CI/CD
data represents a significant portion of data stored in CI/CD tables. Once we
restrict access to processing archived pipelines, we can move this metadata to
a different place - preferably object storage - and make it accessible on
demand, when it is really needed again (for example for compliance or auditing purposes).

Epic: [Link]

### Partition rarely accessed data

After we move CI/CD metadata to a different store, the problem of having
billions of rows describing pipelines, build and artifacts, remains. We still
need to keep reference to the metadata we store in object storage and we still
do need to be able to retrieve this information reliably in bulk (or search
through it).

It means that by moving data to object storage we might not be able to reduce
the number of rows in CI/CD tables. Moving data to object storage should help
with reducing the data size, but not the quantity of entries describing this
data. Because of this limitation, we still want to partition CI/CD data to
reduce the impact on the database (indices size, auto-vacuum time and
frequency).

Partitioning rarely accessed data should also follow the policy defined for
builds archival, to make it consistent and reliable.

Epic: [Link]

### Partition frequently used queuing tables

While working on the [CI/CD Scale](https://docs.gitlab.com/ee/architecture/blueprints/ci_scale/)
architecture, we have introduced a [new architecture for queuing CI/CD builds](https://gitlab.com/groups/gitlab-org/-/epics/5909#note_680407908)
for execution.

This allowed us to significant improve performance, but we still do consider
the new solution as an intermediate mechanism, needed before we start working
on the next iteration, that should improve the architecture of builds queuing
even more (it might require moving off the PostgreSQL fully or partially).

In the meantime we want to ship another iteration, an intermediate step towards
more flexible and reliable solution. We want to partition the new queuing
tables, to reduce the impact on the database, to improve reliability and
database health.

Partitioning of CI/CD queuing tables does not need to follow the policy defined
for builds archival. Instead we should leverage a long-standing policy saying
that builds created more 24 hours ago need to be removed from the queue. This
business rule is present in the product since the inception of GitLab CI.

Epic: [Prepare queuing tables for list-style partitioning](https://gitlab.com/gitlab-org/gitlab/-/issues/347027).

## Caveats

All the three tracks we will use to implement CI/CD time decay pattern are
associated with some challenges. Most important ones are documented below.

### Removing data

While it might be tempting to simply remove old or archived data from our
database, this should be avoided. We should not permanently remove user data
unless a consent is given to do so. We can, however, move data to a different
data store, like object storage.

Archived data can still be needed sometimes (for example for compliance
reasons). We want to be able to retrieve this data if needed, as long as
permanent removal has not been requested or approved by a user.

### Accessing data

Implementing CI/CD data time-decay through partitioning might be challenging
when we still want to make it possible for users to access data stored across
many partitions.

In order to do that we will need to make sure that when archived data needs be
accessed, users provide a time range in which the data has been created. In
order to make it efficient it might be necessary to restrict access to querying
data residing in more than two partitions at once. We can do that by supporting
time ranges spanning the duration that equals to the builds archival policy.

#### Merge request pipelines

Once we partition CI/CD data, especially CI builds, we need to find an
efficient mechanism to present pipeline statuses in merge requests.

How to exactly do that is an implementation detail that we will need to figure
out as the work progresses. We do have many tools to achieve that - data
denormalization, routing reads to proper partitions based on data stored with a
merge request.

## Iterations

All three tacks can be worked on in parallel:

1. [Move archived CI/CD data to object storage](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68228)
2. [Partition CI/CD tables using CI/CD data retention policy](LINK)
3. [Partition CI/CD queuing tables using list partitioning](https://gitlab.com/gitlab-org/gitlab/-/issues/347027)

## Status

Request For Comments.

## Who

Proposal:

<!-- vale gitlab.Spelling = NO -->

| Role                         | Who
|------------------------------|-------------------------|
| Author                       | Grzegorz Bizon          |
| Engineering Leader           | Cheryl Li               |
| Product Manager              | Jackie Porter           |
| Architecture Evolution Coach | Kamil Trzciński         |

DRIs:

| Role                         | Who
|------------------------------|------------------------|
| Leadership                   | Cheryl Li              |
| Product                      | Jackie Porter          |
| Engineering                  | Grzegorz Bizon         |

Domain experts:

| Area                         | Who
|------------------------------|------------------------|
| Continuous Integration       | Marius Bobin           |
| PostgreSQL Database          | Andreas Brandl         |

<!-- vale gitlab.Spelling = YES -->
