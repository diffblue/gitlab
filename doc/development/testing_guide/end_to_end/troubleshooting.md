---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Troubleshooting end-to-end tests

## See what the browser is doing

If something has gone wrong when trying to run the end-to-end tests, it can be very helpful to see what is happening in your
browser when it fails. For example, if the tests don't run at all, it might be because the test framework is trying to
open a URL that isn't valid on your machine, which should be clearer if you see it fail in the browser.

To make the test framework show the browser as it runs the tests, set `WEBDRIVER_HEADLESS=false`. For example:

```shell
cd gitlab/qa
WEBDRIVER_HEADLESS=false bundle exec bin/qa Test::Instance::All http://localhost:3000
```

## Enable logging to see what the test framework tries to do

Sometimes a test might fail and the failure stacktrace doesn't provide enough information to determine what went wrong.
You can get more information by enabling debug logs by setting `QA_DEBUG=true`. For example:

```shell
cd gitlab/qa
QA_DEBUG=true bundle exec bin/qa Test::Instance::All http://localhost:3000
```

The test framework will then output a lot of logs showing the actions taken during the tests. For example:

```plaintext
[date=2022-03-31 23:19:47 from=QA Tests] INFO  -- Starting test: Create Merge request creation from fork can merge feature branch fork to mainline
[date=2022-03-31 23:19:49 from=QA Tests] DEBUG -- has_element? :login_page (wait: 0) returned: true
[date=2022-03-31 23:19:52 from=QA Tests] DEBUG -- filling :login_field with "root"
[date=2022-03-31 23:19:52 from=QA Tests] DEBUG -- filling :password_field with "*****"
[date=2022-03-31 23:19:52 from=QA Tests] DEBUG -- clicking :sign_in_button
```

## Tests don't run at all

This assumes that you're running the tests locally (e.g., on GDK) and you're doing so from the `gitlab/qa/` folder, not via `gitlab-qa`.

If you see a `Net::ReadTimeout` error this might be because the browser is not able to load the specified URL. For example:

```shell
cd gitlab/qa
bundle exec bin/qa Test::Instance::All http://localhost:3000

bundler: failed to load command: bin/qa (bin/qa)
Net::ReadTimeout: Net::ReadTimeout with #<TCPSocket:(closed)>
```

That can happen if you have GitLab running on an address that does not resolve from `localhost`. For example, if you
[set GDK's `hostname` to a specific local IP address](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/run_qa_against_gdk.md#run-qa-tests-against-your-gdk-setup),
you will need to use that IP address instead of `localhost` in the command. For example, if your IP is `192.168.0.12`:

```shell
bundle exec bin/qa Test::Instance::All http://192.168.0.12:3000
```
