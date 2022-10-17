---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Housekeeping **(FREE SELF)**

GitLab supports and automates housekeeping tasks in Git repositories to ensure
that they can be served as efficiently as possible. Housekeeping tasks include:

- Compressing Git objects and revisions.
- Removing unreachable objects.
- Removing stale data like lock files.
- Maintaining data structures that improve performance.
- Updating object pools to improve object deduplication across forks.

WARNING:
Do not manually execute Git commands to perform housekeeping in Git
repositories that are controlled by GitLab. Doing so may lead to corrupt
repositories and data loss.

## Running housekeeping tasks

There are different ways in which GitLab runs housekeeping tasks:

- A project's administrator can [manually trigger](#manual-trigger) repository
  housekeeping tasks.
- GitLab can automatically schedule housekeeping tasks [after a number of Git pushes](#push-based-trigger).

### Manual trigger

Administrators of repositories can manually trigger housekeeping tasks in a
repository. In general this is not required as GitLab knows to automatically run
housekeeping tasks. The manual trigger can be useful when either:

- A repository is known to require housekeeping.
- Automated push-based scheduling of housekeeping tasks has been disabled.

To trigger housekeeping tasks manually:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Settings > General**.
1. Expand **Advanced**.
1. Select **Run housekeeping**.

This starts an asynchronous background worker for the project's repository. The
background worker executes `git gc`, which performs a number of optimizations.

### Push-based trigger

GitLab automatically runs repository housekeeping tasks after a configured
number of pushes:

- [`git gc`](https://git-scm.com/docs/git-gc) runs a number of housekeeping tasks such as:
  - Compressing Git objects to reduce disk space and increase performance.
  - Removing unreachable objects that may have been created from changes to the repository, like force-overwriting branches.
- [`git repack`](https://git-scm.com/docs/git-repack) either:
  - Runs an incremental repack, according to a [configured period](#configure-push-based-maintenance). This
    packs all loose objects into a new packfile and prunes the now-redundant loose objects.
  - Runs a full repack, according to a [configured period](#configure-push-based-maintenance). This repacks all
    packfiles and loose objects into a single new packfile, and deletes the old now-redundant loose
    objects and packfiles. It also optionally creates bitmaps for the new packfile.
- [`git pack-refs`](https://git-scm.com/docs/git-pack-refs) compresses references
  stored as loose files into a single file.

#### Configure push-based maintenance

You can change how often these tasks run when pushes occur, or you can turn
them off entirely:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Repository**.
1. Expand **Repository maintenance**.
1. In the **Housekeeping** section, configure the housekeeping options.
1. Select **Save changes**.

The following housekeeping options are available:

- **Enable automatic repository housekeeping**: Regularly run housekeeping tasks. If you
  keep this setting disabled for a long time, Git repository access on your GitLab server becomes
  slower and your repositories use more disk space.
- **Incremental repack period**: Number of Git pushes after which an incremental `git repack` is
  run.
- **Full repack period**: Number of Git pushes after which a full `git repack` is run.
- **Git GC period**: Number of Git pushes after which `git gc` is run.

As an example, see the following scenario:

- Incremental repack period: 10.
- Full repack period: 50.
- Git GC period: 200.

When the:

- `pushes_since_gc` value is 50, a `repack -A -l -d --pack-kept-objects` runs.
- `pushes_since_gc` value is 200, a `git gc` runs.

Housekeeping also [removes unreferenced LFS files](../raketasks/cleanup.md#remove-unreferenced-lfs-files)
from your project on the same schedule as the `git gc` operation, freeing up storage space for your
project.

## How housekeeping handles pool repositories

Housekeeping for pool repositories is handled differently from standard repositories. It is
ultimately performed by the Gitaly RPC `FetchIntoObjectPool`.

This is the current call stack by which it is invoked:

1. `Repositories::HousekeepingService#execute_gitlab_shell_gc`
1. `Projects::GitGarbageCollectWorker#perform`
1. `Projects::GitDeduplicationService#fetch_from_source`
1. `ObjectPool#fetch`
1. `ObjectPoolService#fetch`
1. `Gitaly::FetchIntoObjectPoolRequest`

To manually invoke it from a [Rails console](operations/rails_console.md) if needed, you can call
`project.pool_repository.object_pool.fetch`. This is a potentially long-running task, though Gitaly
times out in about 8 hours.
