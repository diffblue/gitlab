---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Files API rate limits **(FREE SELF)**

To improve the security and durability of your web application, you can enforce
[rate limits](../../../security/rate_limits.md). You can configure general settings
for [user and IP rate limits](user_and_ip_rate_limits.md).

The [Repository files API](../../../api/repository_files.md) enables you to
fetch, create, update, and delete files in your repository.

## Define Files API rate limits

Prerequisite:

- You must have the Administrator role for your instance.

You can define rate limits for authenticated and unauthenticated Files API
requests:

1. On the top bar, select **Menu > Admin**.
1. In the left sidebar, select **Settings > Network**, and expand **Files API Rate Limits**:

   - Unauthenticated Files API requests
   - Authenticated Files API requests

Rate limits for the Files API are disabled by default. When enabled, they supersede
the general user and IP rate limits for requests to the
[Repository files API](../../../api/repository_files.md). You can therefore
keep the general user and IP rate limits, and increase (if necessary) the rate limits
for the Files API.

Besides this precedence, there are no differences in functionality compared to the general user and
IP rate limits. For more details, see [User and IP rate limits](user_and_ip_rate_limits.md).

## Resources

- [Rate limits](../../../security/rate_limits.md)
- [Repository files API](../../../api/repository_files.md)
- [User and IP rate limits](user_and_ip_rate_limits.md)
