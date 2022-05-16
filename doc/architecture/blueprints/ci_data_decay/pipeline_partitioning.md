---
stage: none
group: unassigned
comments: false
description: 'Pipeline data partitioning design'
---

## Pipeline data partitioning design

_The following contains information related to upcoming products, features, and
functionality._

_It is important to note that the information presented is for informational
purposes only. Please do not rely on this information for purchasing or
planning purposes._

_As with all projects, the items mentioned in this document and linked pages
are subject to change or delay. The development, release and timing of any
products, features, or functionality remain at the sole discretion of GitLab
Inc._

### What problem are we trying to solve?

We want to partition CI/CD dataset, because some of the tables are extremely
large, which might be challenging in terms of scaling reads, even if we ship CI
database decomposition soon.

We want to reduce the risk of database performance degradation by transforming
a few largest database tables into smaller ones using PostgreSQL declarative
partitioning.

See more details about this effort in [the partent blueprint](./).

![pipeline-data-time-decay.png]()

### How are CI/CD data decomposition, partitioning and time-decay related?

CI Decomposition is about extracting a CI database cluster out of the “main”
database cluster, to make it possible to have a different primary database
receiving writes. The main outcome is doubling the capacity for writes and data
storage. Because of the new database cluster not having to serve reads / writes
for non-CI database tables, this will offer small additional capacity for reads
too.

CI Partitioning is about dividing large CI database tables into smaller ones.
The result of this will be an improvement in reads capacity, because it is much
less expensive to read data from small tables, than it is to read data from
large multi-terabytes tables. This will improve performance in other aspects
too, because PostgreSQL will gain more efficiency in maintaining multiple small
tables, in contrast to not-so-efficient maintaining a very large database
table.

CI time-decay is a pattern that allows us to benefit from the strong time-decay
characteristics of pipeline data. It can be implemented in many different ways,
not necessarily related to how we store data in the database, but using
partitioning to implement time-decay might be especially beneficial. Usually to
implement a time decay we mark data as archived, and migrate it out of a
database to a different place once data is no longer relevant or needed.
Because our dataset is extremely large (tens of terabytes) moving such a high
ivolume of data is challenging. With implementing time-decay using partitioning
we can simply archive the entire partition (or set of partitions) by updating a
single record in one of our database tables. It is one of the least expensive
ways to implement time-decay patterns at a database level.

![decomposition-partitioning-comparision.png]()

### Why do we need to partition CI/CD data?

We need to partition CI/CD data because our database tables storing pipelines,
builds, artifacts are too large. `ci_builds` database table is currently 3657
GB large with an index size of 1356 GB. This is a lot and violates our
[principle of 100 GB max size](../database_scaling/size-limits.html). We want
to [build the alerting](https://gitlab.com/gitlab-com/gl-infra/tamland/-/issues/5)
that will notify us when this number is exceeded.

We’ve seen numerous database-related production environment incidents, S1 and
S2, over the last couple of months.

* S1: 2022-03-17 [Increase in writes in `ci_builds` table](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6625)
* S1: 2021-11-22 [Excessive buffer read in replicas for `ci_job_artifacts`](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5952)
* S2: 2022-04-12 [Transactions detected that have been running for more than 10m](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6821)
* S2: 2022-04-06 [Database contention plausibly caused by excessive `ci_builds` reads](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6773)
* S2: 2022-03-18 [Unable to remove a foreign key on `ci_builds`](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6642)

See more detailed data, read from the database in March 2022. We do have around
50 `ci_*` prefixed database tables, some of them would benefit from
partitioning.

Simple SQL query used to get this data:

```sql
WITH tables AS (SELECT table_name FROM information_schema.tables WHERE table_name LIKE 'ci_%')
  SELECT table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) AS total_size,
    pg_size_pretty(pg_relation_size(quote_ident(table_name))) AS table_size,
    pg_size_pretty(pg_indexes_size(quote_ident(table_name))) AS index_size,
    pg_total_relation_size(quote_ident(table_name)) AS total_size_bytes
  FROM tables ORDER BY total_size_bytes DESC;
```

| Table name              | Total size | Index size |
|-------------------------|------------|------------|
| `ci_builds`             | 3.5 TB     | 1 TB       |
| `ci_builds_metadata`    | 1.8 TB     | 150 GB     |
| `ci_job_artifacts`      | 600 GB     | 300 GB     |
| `ci_pipelines`          | 400 GB     | 300 GB     |
| `ci_stages`             | 200 GB     | 120 GB     |
| `ci_pipeline_variables` | 100 GB     | 20 GB      |
|  ... around 40 more     |            |            |

Based on the data in the table above, it is clear that there are tables that we
do store a lot of information in.

Even though we do have almost 50 CI/CD-related database tables, right now we
are interested in partitioning only about 6 of them. It means that we can start
with partitioning the most interesting tables in an iterative way, but we also
should have a strategy for partitioning remaining ones if there is a need to do
so.

### How do we want to partition CI/CD data?

We want to partition CI/CD in iterations. It might not be feasible to partition
all 6 problematic tables at once, so an iterative strategy might be necessary.
We also want to have a strategy for partitioning remaining database tables,
when it becomes necessary.

It is also important to avoid large data migrations. We store almost 6
terabytes of data in the biggest CI/CD tables in many different columns and
indexes. Migrating this amount of data might be challenging and might
potentially cause instability of the production environment. Because of that,
in one of the [first PoCs](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80186)
we’ve found a way to attach an existing database table as a partition zero,
without downtime and excessive database locking. This makes it possible for us
to create a partitioned schema (for example `p_ci_pipelines`) and to attach an
existing `ci_pipelines` table as partition zero. It will be possible to use the
legacy table as usual, but we can create a next partition when we see fit and
the `p_ci_pipelines` table will be used for routing queries. In order to use
the routing table we need to find a good partitioning key.

Our plan is to use logical partition ids. We want to start with the
`ci_pipelines` table and create a `partition_id` column with a DEFAULT value of
100 or 1000. Using a DEFAULT value makes it possible to avoid the challenge of
backfilling this value for every row. By adding a CHECK constraint prior to
attaching the first partition, we can tell PostgreSQL that we’ve already
ensured consistency and there is no need to check it while holding an exclusive
table lock when attaching this table as a partition to the routing table
(partitioned schema definition). Every time we create a new partition for
`p_ci_pipelines` we will increment this value, and the partitioning strategy
will be `LIST` partitioning.

We will also create a `partition_id` column in the other 6 database tables we
want to initially, iteratively partition. Once a new pipeline gets created, it
will get `partition_id` assigned, and all the related resources like builds,
artifacts, will share the same value. We want to add a `partition_id` column to
all the 6 problematic tables because this way we can avoid backfilling this
data when we decide it is time to ship partitioning.

Because we want to partition CI/CD data iteratively, it means that we will
start with the pipelines table, and create at least one partition, but
presumably another one too. The pipeline table will be partitioned using `LIST`
partitioning strategy. It means that it is possible that `p_ci_pipelines` will
store data in two partitions with ids 100 and 101. Then we will take a stab at
partitioning `ci_builds` and therefore in case of `p_ci_builds` we will need to
use `RANGE` partitioning with ids 100 - 101, since builds for the two logical
partitions used will still be stored in a single table. It means that physical
partitioning and logical partitioning will be separated, and determined by the
time when we ship partitioning for respective database tables. Using `RANGE`
partitioning will works similarly to using `LIST` partitioning in case of other
database tables than `ci_pipelines`, but because we can guarantee continuity of
`partition_id` values, using `RANGE` partitioning might be a bit better
strategy.

### Why do we want to use explicit logical partition ids?

Partitioning CI/CD data using logical `partition_id` has several benefits. We
could partition by a primary key, but this would introduce much more complexity
and additional cognitive load required to understand how the data is being
structured and stored.

CI/CD data is hierarchical data. Stages belong to pipelines, builds belong to
stages, artifacts belong to builds (with rare exceptions). We want to design a
partitioning strategy that reflects this hierarchy to reduce the complexity and
cognitive load imposed on contributors.  With explicit `partition_id`
associated with a pipeline, we can cascade the pipeline id number when trying
to retrieve all resources associated with a pipeline. We know that for pipeline
12345, that has `partition_id` 102, we are always able to find associated
resources in logical partitions with number 102 in other routing tables, and
PostgreSQL will know in which partitions these records are being stored for
every table.

Another interesting benefit for using a single and incremental latest
`partition_id` number, associated with a least pipeline, is that in theory we
cache it in Redis / in memory to avoid excessive reads from the database to
find this number, although we might not need to do this. The point here is that
the single `partition_id` value for a pipeline gives us more choices later on
than primary-keys-based partitioning.

### Splitting large partitions into smaller ones

We want to start with the initial `pipeline_id` number 100 (or higher, like
1000, depending on our calculations / estimations). We do not want to start
from 1, because we realize that existing tables are also large already, and we
might want to split them into smaller partitions. If we start with 100, we will
be able to create partitions for `partition_id` 1, 20, 45, and move existing
records there by updating `partition_id` from 100 to a smaller number.
PostgreSQL will move these records into their respective partitions in a
consistent way, provided that we do that in a transaction for all pipeline
resources at the same time. If we ever decide to split large partitions into
smaller ones (this is not something we know we will need to do for sure) we
might be able to just use Background Migrations, and PostgreSQL will be smart
enough to move rows between partitions.

### Storing partitions metadata in the database

In order to build an efficient mechanism that will be responsible for creating
new partitions, and to implement time decay we want to introduce a partitioning
metadata table, called `ci_partitions`. In that table we would store metadata
about all the logical partitions, with many pipelines per partition. We may
need to store a range of pipeline ids per logical partition. Using it we will
be able to find the `partition_id` number for a given pipeline id and we will
also find information about which logical partitions are “active” or
“archived”, which will help us to implement a time-decay pattern using database
declarative partitioning.

`ci_partitions` table will store information about a partition identifier,
pipeline ids range it is valid for and whether the partitions have been
archived or not.

### Implementing time-decay pattern using partitioning

We can use `ci_partitions` to implement a time-decay pattern using declarative
partitioning. By telling PostgreSQL which logical partitions are archived we
can stop reading from these partitions using a SQL query like the one below.

```sql
SELECT * FROM ci_builds WHERE partition_id IN (
  SELECT id FROM ci_partitions WHERE active = true
);
```

This query will make it possible to limit the number of partitions we will read
from, and therefore will cut access to “archived” pipeline data, using our data
retention policy for CI/CD data. Ideally we do not want to read from more than
two partitions at once, hence we will need to align the automatic partitioning
mechanisms with the time-decay policy. We will still need to implement new
access patterns for the archived data, presumably through the API, but the cost
of storing archived data in PostgreSQL will be reduced significantly this way.

There are some technical details here that are out of the scope of this
description, but by using this strategy we can “archive” data, and make it much
less expensive to reside in our PostgreSQL cluster, by simply toggling a
boolean value.

### Accessing partitioned data

It will be possible to access partitioned data whether it has been archived or
not, in most of the places in GitLab. On a merge request page, we will always
show pipeline details even if a merge request has been created years ago. We
can do that because `ci_partitions` will be a lookup table associating pipeline
id with its `partition_id`, and we will be able to find a partition that all
pipeline data is being stored in.

We will need to constraint access to searching through all pipelines, builds,
artifacts etc. It will be necessary to have different access patterns to
accessing archived data, in the UI and API.

There are a few challenges in enforcing usage of the `partition_id`
partitioning key in PostgreSQL. To make it easier to update our application to
support this, we have designed a new queries analyzer in our
[PoC merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/80186).
It helps to find queries that are not using the partitioning key.

In a [Proof of Concept merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/84071)
/ [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/357090) we have
demonstrated that using the uniform `partition_id` makes it possible to extend
Rails associations with additional scope modifier that will allow us to provide
the partitioning key in the SQL query.

Using instance dependent associations, we can easily append partitioning key to
SQL queries that are supposed to retrieve associated pipeline resources, like:

```ruby
has_many :builds, -> (pipeline) { where(partition_id: pipeline.partition_id) }
```

The problem with that approach is that it makes preloading much more difficult
as instance dependent associations can not be used with preloads:

> ArgumentError: The association scope 'builds' is instance dependent (the
> scope block takes an argument). Preloading instance dependent scopes is not
> supported.

We also need to build a Proof of Concept for removing data on the PostgreSQL
side (using foreign keys with `ON DELETE CASCADE`) and removing data through
Rails associations, as this might be an important area of uncertainty.

We need to [better
understand](https://gitlab.com/gitlab-org/gitlab/-/issues/360148) how unique
constraints we are currently using will perform in case of using the
partitioned schema.

We have also designed a query analyzer that makes it possible to detect direct
usage of partitions zero, legay tables that have been attached as first
partitions to routing tables, to ensure that all queries are targeting
partitioned schema / partitioned routing tables, like `p_ci_pipelines`.

### Why do we not want to partition using project / namespace identifier?

We do not want to partition using `project_id / namespace_id` because sharding
/ podding is a different problem to solve, on a different layer of the
application. It doesn’t solve the original problem statement of performance
growing worse over time as we build up infrequently read data. We want to
introduce GitLab Pods in the future, and that is the primary mechanism of
separating data based on a group or project the data is associated with.

In theory we could use either `project_id` or `namespace_id` as a second
partitioning dimension, but this would add more complexity to the problem that
is complex enough already.

### Partitioning builds queuing tables

We also do want to partition our builds queuing tables. Currently we do have
two - `ci_pending_builds` and `ci_running_builds`. These tables are different
from other CI/CD data tables, as there are business rules in our product that
make all data stored in them invalid after 24 hours.

It means that we will need to use a different strategy to partition these
database tables, by removing partitions entirely after these are older than 24
hours, and always reading from two partitions through a routing table. The
strategy to partition these tables is well understood, but requires a solid
Ruby-based automation to manage the creation and deletion of these partitions.
In order to achieve that we will collaborate with the Database team to adapt
[existing database partitioning tools](/../../../database/table_partitioning.html)
to support CI/CD data partitioning.

### Iterating to reduce the risk

This strategy should reduce the risk of shipping CI/CD partitioning to
acceptable levels. We are aware that because of exponential growth of CI/CD
data this is quite urgent, hence we also focus on shipping partitioning for
reading only two partitions initially to make it possible to detach partitions
zero in case of problems in our production environment.

### Iterations

We want to first focus on Phase 1 interaction. The goal and the main objective
of this iteration is to partition the biggest 6 CI database tables into 6
routing tables (partitioned schema) and 12 partitions. This will leave our
Rails SQL queries mostly unchanged, but it will also make it possible to
perform emergency detachment of “zero partitions” in case of a database
performance degradation. This will cut users off their old data, but the
application will remain operable, up and running, which is a better alternative
to application-wide outage.

1. Phase 0: Build CI/CD data partitioning strategy: DONE ✅
1. Phase 1: Partition the 6 biggest CI/CD database tables.
    1. Create partitioned schema for all 6 database tables
    1. Design a way to cascade `partition_id` to all partitioned resources.
    1. Ship initial query analyzers validating that we target routing tables.
    1. Attach zero partitions to the partitioned database tables.
    1. Update the application to target routing tables / partitioned tables.
    1. Measure performance and efficiency of this solution.
    Revert strategy: Switch back to using concrete partitions instead of routing tables.
1. Phase 2: Add partitioning key to add SQL queries targeting partitioned tables.
    1. Ship queries analyzer checking if queries targeting partitioned tables
       are using proper partitioning keys.
    1. Modify existing queries to make sure that all of them are using a
       partitioning key as a filter.
     Revert strategy: Using feature flags query-by-query.
1. Phase 3: Build new partitioned data access patterns.
    1. Build new API or extend existing one to allow access to data stored in
       partitions that are supposed to be excluded based on the time-decay data
       retention policy.
    Revert strategy: Feature flags.
1. Phase 4: Introduce time-decay mechanisms built on top of partitioning.
    1. Build time-decay policy mechanisms.
    1. Enable time-decay strategy on GitLab.com
1. Phase 5: Introduce mechanisms for creating partitions automatically.
    1. Make it possible to create partitions in an automatic way.
    1. Ship new architecture to self-managed instances.

## Conclusions

We want to build a solid strategy for partitioning CI/CD data. We are aware of
the fact that it is difficult to iterate on this design, because a mistake made
in managing the database schema of our multi-terabyte PostgreSQL instance might
not be easily reversible without a potential downtime. That is the reason why
we are spending a significant amount of time to research and refine our
partitioning strategy. Mistakes are risky, therefore we iterate on refining the
strategy even before we start shipping changes to our database and code.

We’ve managed to find a way to avoid large-scale data migrations, and we are
building an iterative strategy for partitioning CI/CD data. In order to
finalize building this strategy we started documenting all our findings in this
document and shipping additional Proof of Concepts for areas that we do not
have enough confidence in.

## Who

Authors:

<!-- vale gitlab.Spelling = NO -->

| Role                         | Who
|------------------------------|-------------------------|
| Author                       | Grzegorz Bizon          |

Recommenders:


| Who                         | Role
|-----------------------------|------------------------|
| Kamil Trzciński             | Distingiushed Engineer |

<!-- vale gitlab.Spelling = YES -->
