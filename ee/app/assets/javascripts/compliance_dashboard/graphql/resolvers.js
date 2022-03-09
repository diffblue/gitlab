// Note: This is mocking the server response until https://gitlab.com/gitlab-org/gitlab/-/issues/342897 is complete
// These values do not need to be translatable as it will remain behind a development feature flag
// until that issue is merged

/* eslint-disable @gitlab/require-i18n-strings */
export default {
  Query: {
    group() {
      return {
        __typename: 'Group',
        id: 1,
        mergeRequestViolations: {
          __typename: 'MergeRequestViolations',
          nodes: [
            {
              __typename: 'MergeRequestViolation',
              id: 1,
              severityLevel: 'HIGH',
              reason: 'APPROVED_BY_COMMITTER',
              violatingUser: {
                __typename: 'Violator',
                id: 50,
                name: 'John Doe6',
                username: 'user6',
                avatarUrl:
                  'https://secure.gravatar.com/avatar/7ff9b8111da2e2109e7b66f37aa632cc?s=80&d=identicon',
                webUrl: 'https://gdk.localhost:3443/user6',
              },
              mergeRequest: {
                __typename: 'MergeRequest',
                id: 24,
                title:
                  'Officiis architecto voluptas ut sit qui qui quisquam sequi consectetur porro.',
                mergedAt: '2021-11-25T11:56:52.215Z',
                webUrl: 'https://gdk.localhost:3443/gitlab-org/gitlab-shell/-/merge_requests/1',
                author: {
                  __typename: 'Author',
                  id: 50,
                  name: 'John Doe6',
                  username: 'user6',
                  avatarUrl:
                    'https://secure.gravatar.com/avatar/7ff9b8111da2e2109e7b66f37aa632cc?s=80&d=identicon',
                  webUrl: 'https://gdk.localhost:3443/user6',
                },
                mergeUser: {
                  __typename: 'MergedBy',
                  id: 50,
                  name: 'John Doe6',
                  username: 'user6',
                  avatarUrl:
                    'https://secure.gravatar.com/avatar/7ff9b8111da2e2109e7b66f37aa632cc?s=80&d=identicon',
                  webUrl: 'https://gdk.localhost:3443/user6',
                },
                committers: {
                  __typename: 'Committers',
                  nodes: [],
                },
                participants: {
                  __typename: 'Participants',
                  nodes: [
                    {
                      __typename: 'User',
                      id: 50,
                      name: 'John Doe6',
                      username: 'user6',
                      avatarUrl:
                        'https://secure.gravatar.com/avatar/7ff9b8111da2e2109e7b66f37aa632cc?s=80&d=identicon',
                      webUrl: 'https://gdk.localhost:3443/user6',
                    },
                  ],
                },
                approvedBy: {
                  __typename: 'ApprovedBy',
                  nodes: [
                    {
                      __typename: 'User',
                      id: 49,
                      name: 'John Doe5',
                      username: 'user5',
                      avatarUrl:
                        'https://secure.gravatar.com/avatar/eaafc9b0f704edaf23cd5cf7727df560?s=80&d=identicon',
                      webUrl: 'https://gdk.localhost:3443/user5',
                    },
                    {
                      __typename: 'ApprovedBy',
                      id: 48,
                      name: 'John Doe4',
                      username: 'user4',
                      avatarUrl:
                        'https://secure.gravatar.com/avatar/5c8881fc63652c86cd4b23101268cf84?s=80&d=identicon',
                      webUrl: 'https://gdk.localhost:3443/user4',
                    },
                  ],
                },
                fullRef: 'gitlab-shell!1',
                ref: '!1',
                sourceBranch: 'ut-171ad4e263',
                sourceBranchExists: false,
                targetBranch: 'master',
                targetBranchExists: true,
                project: {
                  __typename: 'Project',
                  id: 1,
                  avatarUrl: null,
                  name: 'Gitlab Shell',
                  webUrl: 'https://gdk.localhost:3443/gitlab-org/gitlab-shell',
                  complianceFrameworks: {
                    __typename: 'ComplianceFrameworks',
                    nodes: [
                      {
                        __typename: 'ComplianceFrameworks',
                        id: 1,
                        name: 'GDPR',
                        description: 'General Data Protection Regulation',
                        color: '#009966',
                      },
                    ],
                  },
                },
              },
            },
            {
              __typename: 'MergeRequestViolation',
              id: 2,
              severityLevel: 'HIGH',
              reason: 'APPROVED_BY_INSUFFICIENT_USERS',
              violatingUser: {
                __typename: 'Violator',
                id: 50,
                name: 'John Doe6',
                username: 'user6',
                avatarUrl:
                  'https://secure.gravatar.com/avatar/7ff9b8111da2e2109e7b66f37aa632cc?s=80&d=identicon',
                webUrl: 'https://gdk.localhost:3443/user6',
              },
              mergeRequest: {
                __typename: 'MergeRequest',
                id: 25,
                title:
                  'Officiis architecto voluptas ut sit qui qui quisquam sequi consectetur porro.',
                mergedAt: '2021-11-25T11:56:52.215Z',
                webUrl: 'https://gdk.localhost:3443/gitlab-org/gitlab-test/-/merge_requests/2',
                author: {
                  __typename: 'Author',
                  id: 50,
                  name: 'John Doe6',
                  username: 'user6',
                  avatarUrl:
                    'https://secure.gravatar.com/avatar/7ff9b8111da2e2109e7b66f37aa632cc?s=80&d=identicon',
                  webUrl: 'https://gdk.localhost:3443/user6',
                },
                mergeUser: {
                  __typename: 'MergedBy',
                  id: 50,
                  name: 'John Doe6',
                  username: 'user6',
                  avatarUrl:
                    'https://secure.gravatar.com/avatar/7ff9b8111da2e2109e7b66f37aa632cc?s=80&d=identicon',
                  webUrl: 'https://gdk.localhost:3443/user6',
                },
                committers: {
                  __typename: 'Committers',
                  nodes: [],
                },
                participants: {
                  __typename: 'Participants',
                  nodes: [
                    {
                      __typename: 'User',
                      id: 50,
                      name: 'John Doe6',
                      username: 'user6',
                      avatarUrl:
                        'https://secure.gravatar.com/avatar/7ff9b8111da2e2109e7b66f37aa632cc?s=80&d=identicon',
                      webUrl: 'https://gdk.localhost:3443/user6',
                    },
                  ],
                },
                approvedBy: {
                  __typename: 'ApprovedBy',
                  nodes: [
                    {
                      __typename: 'User',
                      id: 49,
                      name: 'John Doe5',
                      username: 'user5',
                      avatarUrl:
                        'https://secure.gravatar.com/avatar/eaafc9b0f704edaf23cd5cf7727df560?s=80&d=identicon',
                      webUrl: 'https://gdk.localhost:3443/user5',
                    },
                  ],
                },
                fullRef: 'gitlab-test!2',
                ref: '!2',
                sourceBranch: 'ut-171ad4e264',
                sourceBranchExists: false,
                targetBranch: 'master',
                targetBranchExists: true,
                project: {
                  __typename: 'Project',
                  id: 2,
                  avatarUrl: null,
                  name: 'Gitlab Test',
                  webUrl: 'https://gdk.localhost:3443/gitlab-org/gitlab-test',
                  complianceFrameworks: {
                    __typename: 'ComplianceFrameworks',
                    nodes: [
                      {
                        __typename: 'ComplianceFrameworks',
                        id: 2,
                        name: 'SOX',
                        description: 'A framework',
                        color: '#00FF00',
                      },
                    ],
                  },
                },
              },
            },
          ],
          pageInfo: {
            __typename: 'PageInfo',
            hasNextPage: true,
            hasPreviousPage: false,
            startCursor: 'eyJpZCI6IjMzMjkwNjMzIn0',
            endCursor: 'eyJpZCI6IjMzMjkwNjI5In0',
          },
        },
      };
    },
  },
};
