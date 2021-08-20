---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Files API Rate Limits **(FREE SELF)**

Rate limiting is a common technique used to improve the security and durability of a web
application. For more details, see [Rate limits](../../../security/rate_limits.md). General user and
IP rate limits can be enforced from the top bar at
**Menu > Admin > Settings > Network > User and IP rate limits**.
For more details, see [User and IP rate limits](user_and_ip_rate_limits.md).

You can fetch, create, update, and delete files through the [Repository files API](../../../api/repository_files.md).

You can define specific rate limits for the Files API in
**Menu > Admin > Settings > Network > Files API Rate Limits**:

- Unauthenticated Files API requests
- Authenticated Files API requests

These limits are disabled by default. When enabled, they supersede the general user and IP rate
limits for requests to the Files API. You can therefore keep the general user and IP rate limits,
and increase (if necessary) the rate limits for the Files API.

Besides this precedence, there are no differences in functionality compared to the general user and
IP rate limits. For more details, see [User and IP rate limits](user_and_ip_rate_limits.md).
