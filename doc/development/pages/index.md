---
type: reference, dev
stage: Create
group: Editor
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: "GitLab's development guidelines for GitLab Pages"
---

# Getting started with development

## Configuring GitLab Pages hostname

GitLab Pages needs a hostname/domain, since each different pages sites is accessed via a
subdomain. GitLab Pages hostname can be set in different manners, like:

### Without wildcard, editing `/etc/hosts`

Since `/etc/hosts` don't support wildcard hostnames, you'll have to add to your configuration one
entry for the GitLab Pages and then one entry for each page site.

   ```text
   127.0.0.1 gdk.test           # If you're using GDK
   127.0.0.1 pages.gdk.test     # Pages host
   # Any namespace/group/user needs to be added
   # as a subdomain to the pages host. This is because
   # /etc/hosts doesn't accept wildcards
   127.0.0.1 root.pages.gdk.test # for the root pages
   ```

### With dns wildcard alternatives

If instead of editing your `/etc/hosts` you'd prefer to use a dns wildcard, you can use:

- [`nip.io`](https://nip.io)
- [`dnsmasq`](https://wiki.debian.org/dnsmasq)

## Configuring GitLab Pages without GDK

Create a `gitlab-pages.conf` in the root of the GitLab Pages site, like:

```toml
listen-http=:3010             # default port is 3010, but you can use any other
pages-domain=pages.gdk.test   # your local GitLab Pages domain
pages-root=shared/pages       # directory where the pages are stored
log-verbose=true              # show more information in the logs
```

To see more options you can check [`internal/config/flags.go`](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/internal/config/flags.go)
or run `gitlab-pages --help`.

### Running GitLab Pages manually

For any changes in the code, you must run `make` to build the app, so it's best to just always run
it before you start the app. It's quick to build so don't worry!

```sh
make && ./gitlab-pages -config=gitlab-pages.conf
```

## Configuring GitLab Pages with GDK

In the following steps, `$GDK_ROOT` is the directory where you cloned GDK.

1. Set up the [GDK hostname](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/local_network.md).
1. Add a [GitLab Pages hostname](#configuring-gitlab-pages-hostname) to the `gdk.yml`:

   ```yaml
   gitlab_pages:
     enabled: true         # enable GitLab Pages to be managed by gdk
     port: 3010            # default port is 3010
     host: pages.gdk.test  # the GitLab Pages domain
     auto_update: true     # if gdk must update GitLab Pages git
     verbose: true         # show more information in the logs
   ```

### Running GitLab Pages with GDK

Once these configurations are set GDK will manage a GitLab Pages process and you'll have access to
it with commands like:

   ```sh
   $ gdk start gitlab-pages   # start GitLab Pages
   $ gdk stop gitlab-pages    # stop GitLab Pages
   $ gdk restart gitlab-pages # restart GitLab Pages
   $ gdk tail gitlab-pages    # tail GitLab Pages logs
   ```

### Running GitLab Pages manually

You can also build and start the app independent of GDK processes management.

For any changes in the code, you must run `make` to build the app, so it's best to just always run
it before you start the app. It's quick to build so don't worry!

```sh
make && ./gitlab-pages -config=gitlab-pages.conf
```

#### Building Gitlab Pages in FIPS mode

```sh
$ FIPS_MODE=1 make && ./gitlab-pages -config=gitlab-pages.conf
```

### Creating GitLab Pages site

To build a GitLab Pages site locally you'll have to [configure `gitlab-runner`](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/runner.md)

Check the [user manual](https://docs.gitlab.com/ee/user/project/pages/).

### Enabling access control

GitLab Pages have support to private sites, which means sites that only people who has access to the
Gitlab's project will have access to its GitLab Pages site.

GitLab Pages access control is disabled by default. To enable it:

1. Enable the GitLab Pages access control within GitLab itlsef, which can be done by editing
   `gitlab.yml` or in the `gdk.yml` if you're using GDK.

   ```yaml
   # gitlab/config/gitlab.yml
   pages:
     access_control: true
   ```

   or

   ```yaml
   # $GDK_ROOT/gdk.yml
   gitlab_pages:
     enabled: true
     access_control: true
   ```

1. Restart GitLab (if running through the GDK, run `gdk restart`). Note that running
   `gdk reconfigure` overwrites the value of `access_control` in `config/gitlab.yml`.
1. In your local GitLab instance, in the browser navigate to `http://gdk.test:3000/admin/applications`.
1. Create an [Instance-wide OAuth application](https://docs.gitlab.com/ee/integration/oauth_provider.html#instance-wide-applications).
   - The scope is `api`
1. Set the value of your `redirect-uri` to the `pages-domain` authorization endpoint
   - `http://pages.gdk.test:3010/auth`, for example
   - Note that the `redirect-uri` must not contain any GitLab Pages site domain
1. Add the auth client configuration:

   - with GDK, in `gdk.yml`:

      ```yaml
      gitlab_pages:
        enabled: true
        access_control: true
        auth_client_id: $CLIENT_ID           # the OAuth application id created in http://gdk.test:3000/admin/applications
        auth_client_secret: $CLIENT_SECRET   # the OAuth application secret created in http://gdk.test:3000/admin/applications
      ```

      GDK generates random `auth_secret` and builds the `auth_redirect_uri` based on GitLab Pages
      host configuration.

   - without GDK, in `gitlab-pages.conf`:

      ```conf
      ## the following are only needed if you want to test auth for private projects
      auth-client-id=$CLIENT_ID                         # the OAuth application id created in http://gdk.test:3000/admin/applications
      auth-client-secret=$CLIENT_SECRET                 # the OAuth application secret created in http://gdk.test:3000/admin/applications
      auth-secret=$SOME_RANDOM_STRING                   # should be at least 32 bytes long
      auth-redirect-uri=http://pages.gdk.test:3010/auth # the authentication callback url for GitLab Pages
      ```

1. If running Pages inside the GDK you can use GDK's `protected_config_files` section under `gdk` in
   your `gdk.yml` to avoid getting `gitlab-pages.conf` configuration rewritten:

   ```yaml
   gdk:
     protected_config_files:
     - 'gitlab-pages/gitlab-pages.conf'
   ```

## Linting

```sh
# Run the linter locally
make lint
```

## Testing

To run tests, you can use these commands:

```sh
# This will run all of the tests in the codebase
make test

# Run a specfic test file
go test ./internal/serving/disk/

# Run a specific test in a file
go test ./internal/serving/disk/ -run TestDisk_ServeFileHTTP

# Run all unit tests except acceptance_test.go
go test ./... -short

# Run acceptance_test.go only
make acceptance
# Run specific acceptance tests
# We add `make` here because acceptance tests use the last binary that was compiled,
# so we want to have the latest changes in the build that is tested
make && go test ./ -run TestRedirect
```
