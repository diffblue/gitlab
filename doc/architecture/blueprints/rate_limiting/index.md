---
stage: none
group: unassigned
comments: false
description: 'Next Rate Limiting Architecture'
---

# Next Rate Limiting Architecture

## Summary

Introducing reasonable application limits is a very important step in any SaaS
platform scaling strategy. The more users a SaaS platform has, the more
important it is to introduce sensible rate limiting and policies enforcement
that will help to achieve availability goals, will reduce the problem of noisy
neighbours for users and will ensure that they can keep using a platform
successfully.

This especially true for GitLab.com. Our goal is to have a reasonable and
transparent strategy for enforcing application limits, which will become a
definition of a responsible usage, to help us with keeping our availability and
user satisfaction at a desired level.

We've been introducing various application limits for many years already, but
we've never had a consistent strategy for doing it. A consistent framework used
by engineers and product managers, across entire application stack, to define,
expose and enforce limits and policies, is something we want to build now.

Lack of consistency in defining limits, not being able to expose them to our
users, support engineers and satellite services, has negative impact on our
productivity, makes it difficult to introduce new limits and eventually
prevents us from enforcing responsible usage on all layers of our application
stack.

This blueprint has been written to consolidate our limits and to describe the
vision of our next rate limiting and policies enforcement architecture.

_Disclaimer: The following contains information related to upcoming products,
features, and functionality._

_It is important to note that the information presented is for informational
purposes only. Please do not rely on this information for purchasing or
planning purposes._

_As with all projects, the items mentioned in this document and linked pages are
subject to change or delay. The development, release and timing of any
products, features, or functionality remain at the sole discretion of GitLab
Inc._

## Goals

**Implement a next architecture for rate limiting and policies definition.**

## Challenges

* We have many ways to define application limits, in many different places.
* It is difficult to understand what limits have been applied to a request.
* It is difficult to introduce new limits even even more to define policies.
* Finding what limits are defined requires performing a codebase audit.
* We don't have a good way to expose limits to satellite services like Registry.
* We need to build external services to enforce policies (Pipeline Validation Service).
* There is not standardized way to define policies in a way consistent with defining limits.
* It is difficult to understand when a user is approach a limit threshold.
* There is no way to automatically notify a user when they are approaching thresholds.
* There is no single way to change limits for a namespace / project / user / customer.
* There is no single way to monitor limits through real-time metrics.

## Opportunity

We want to build a new framework, making it easier to define limits and
policies, and to enforce and adjust them in a way controlled through robust
monitoring capabilities.

<!-- markdownlint-disable MD029 -->

1. Build a framework to define and enforce limits in GitLab Rails.
2. Build an API to consume limits in satellite service and expose them to users.
3. Build a GitLab Policy Service in place of the Pipeline Validation Service.

<!-- markdownlint-enable MD029 -->

Consolidation layers: ELABORATE.

### Framework to define and enforce limits

First we want to build a new framework that will allow us to define and enforce
application limits, in the GitLab Rails project context, in a more consistent
and established way. In order to do that, we will need to build a new
abstraction that will tell engineers how to define a limit in a structured way
(presumably using YAML or Cue format) and then how to consume the limit in the
application itself.

We envision building a simple Ruby library here (we can add it to labkit-ruby)
that will make it trivial for engineers to check if a certain limit has been
exceeded or not.

```yaml
name: my_limit_name
actors: user
context: project, group, pipeline
type: rate / second
group: pipeline::execution
limits:
  warn: 2B / day
  soft: 100k / s
  hard: 500k / s
```

```ruby
Gitlab::Limits::RateThreshold.enforce(:my_limit_name) do |threshold|
  actor   = current_user
  context = current_project

  threshold.available do |limit|
    # ...
  end

  threshold.approaching do |limit|
    # ...
  end

  threshold.exceeded do |limit|
    # ...
  end
end
```

In the example above, when `my_limit_name` is defined in YAML, engineers will
be check the current state and execute  appropriate  code block depending on the
past usage / resource consumption.

Things we want to build and support by default:

1. Comprehensive dashboards showing how often limits are being hit.
1. Notifications about the risk of hitting limits.
1. Automation checking if limits definitions are being enforced properly.
1. Different types of limits - time bound / number per resource etc.
1. A panel that makes it easy to override limits per plan / namespace.
1. Logging that will expose limits applied in Kibana.
1. An automatically generated documentation page will all limits described.

### API to expose limits and policies

Once we have an established and consistent way to define application limits we
can build a few API endpoints that will allow us to expose them to our users,
customers and other satellite services that may want to consume them.

Users will be able to ask the API about the limits / thresholds that have been
set for them, how often they are hitting them, and what impact those might have
on their business. This kind of transparency can help them with communicating
their needs to customer success team at GitLab, and we will be able to
communicate how the responsible usage is defined at a given moment.

Because of how GitLab architecture has been built, GitLab Rails application, in
most cases, behaves as a central enterprise service bus (ESB) and there are a
few satellite services communicating with it. Services like Container Registry,
GitLab Runners, Gitaly, Workhorse, KAS could use the API to receive a set of
application limits those are supposed to enforce. This will still allow us to
define all of them in a single place.

### GitLab Policy Service

Not all limits can be easily defined in YAML. There are some more complex
policies that require a bit more sophisticated and declarative programming
language to describe them. One example of such language might be
[Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) language.
It is a standardized way to define policies in
[OPA - Open Policy Agent](https://www.openpolicyagent.org/). At GitLab we are
already using OPA in some departments. We envision the need to additional
consolidation to not only consolidate on the tooling we are using internally at
GitLab, but to also transform the Next Rate Limiting Architecture into
something we can make a part of the product itself.

Today, we already do have a policy service we are using to decide whether a
pipeline can be created or not. There are many policies defined in
[Pipeline Validation Service](https://gitlab.com/gitlab-org/modelops/anti-abuse/pipeline-validation-service).
There is a significant opportunity here in transforming Pipeline Validation
Service into a general purpose GitLab Policy Service / GitLab Policy Agent that
will be well integrated into the GitLab product itself.

## Principles

1. Try to avoid building rate limiting framework in a tightly coupled way.
1. Build application limits API in a way that it can be easily extracted to a separate service.
1. Build application limits definition in a way that is independent from the Rails application.
1. TODO: add more principles ...

## Iterations


## Status

Request For Comments.

## Timeline

- 2022-04-27: [Rate Limit Architecture Working Group](https://about.gitlab.com/company/team/structure/working-groups/rate-limit-architecture/) started.
- 2022-06-07: Working Group members [started submitting technical proposals](https://gitlab.com/gitlab-org/gitlab/-/issues/364524) for the next rate limiting architecture.
- 2022-06-15: We started [scoring proposals](https://docs.google.com/spreadsheets/d/1DFHU1kSdTnpydwM5P2RK8NhVBNWgEHvzT72eOhB8F9E) submitted by Working Group members.
- 2022-07-06: A fourth, [consolidated proposal](https://gitlab.com/gitlab-org/gitlab/-/issues/364524#note_1017640650), has been submitted.
- 2022-07-12: Started working on the design document following [Architecture Evolution Workflow](https://about.gitlab.com/handbook/engineering/architecture/workflow/).

## Who

Proposal:

<!-- vale gitlab.Spelling = NO -->

| Role                         | Who
|------------------------------|-------------------------|
| Author                       | Grzegorz Bizon          |
| Author                       | Fabio Pitino            |
| Author                       | Marshall Cottrell       |
| Author                       | Hayley Swimelar         |
| Engineering Leader           | Sam Goldstein           |
| Product Manager              |                         |
| Architecture Evolution Coach |                         |
| Recommender                  |                         |
| Recommender                  |                         |
| Recommender                  |                         |
| Recommender                  |                         |

DRIs:

| Role                         | Who
|------------------------------|------------------------|
| Leadership                   |                        |
| Product                      |                        |
| Engineering                  |                        |

Domain experts:

| Area                         | Who
|------------------------------|------------------------|
|                              |                        |

<!-- vale gitlab.Spelling = YES -->
