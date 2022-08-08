---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Markdown API **(FREE)**

> Authentication requirement [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/93727) in GitLab 15.3.

All API calls to the Markdown API must be [authenticated](index.md#authentication).

Available only in APIv4.

## Render an arbitrary Markdown document

```plaintext
POST /markdown
```

| Attribute | Type    | Required      | Description                                |
| --------- | ------- | ------------- | ------------------------------------------ |
| `text`    | string  | yes           | The Markdown text to render                |
| `gfm`     | boolean | no            | Render text using GitLab Flavored Markdown. Default is `false` |
| `project` | string  | no            | Use `project` as a context when creating references using GitLab Flavored Markdown  |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type:application/json" \
  --data '{"text":"Hello world! :tada:", "gfm":true, "project":"group_example/project_example"}' "https://gitlab.example.com/api/v4/markdown"
```

Response example:

```json
{ "html": "<p dir=\"auto\">Hello world! <gl-emoji title=\"party popper\" data-name=\"tada\" data-unicode-version=\"6.0\">🎉</gl-emoji></p>" }
```
