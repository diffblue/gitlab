export const createUser = (id) => ({
  id,
  avatar_url: `https://${id}`,
  name: `User ${id}`,
  state: 'active',
  username: `user-${id}`,
  web_url: `http://localhost:3000/user-${id}`,
});

export const mergedAt = () => {
  const date = new Date();

  date.setFullYear(2020, 0, 1);
  date.setHours(0, 0, 0, 0);

  return date.toISOString();
};

export const createPipelineStatus = (status) => ({
  details_path: '/h5bp/html5-boilerplate/-/pipelines/58',
  favicon: '',
  group: status,
  has_details: true,
  icon: `status_${status}`,
  illustration: null,
  label: status,
  text: status,
  tooltip: status,
});

export const createMergeRequest = ({ id = 1, props } = {}) => {
  const mergeRequest = {
    id,
    approved_by_users: [],
    committers: [],
    participants: [],
    issuable_reference: 'project!1',
    reference: '!1',
    merged_at: mergedAt(),
    milestone: null,
    path: `/h5bp/html5-boilerplate/-/merge_requests/${id}`,
    title: `Merge request ${id}`,
    author: createUser(id),
    merged_by: createUser(id),
    pipeline_status: createPipelineStatus('success'),
    approval_status: 'success',
    project: {
      avatar_url: '/foo/bar.png',
      name: 'Foo',
      web_url: 'https://foo.com/project',
    },
  };

  return { ...mergeRequest, ...props };
};

export const createApprovers = (count) => {
  return Array(count)
    .fill(null)
    .map((_, id) => createUser(id));
};

export const createMergeRequests = ({ count = 1, props = {} } = {}) => {
  return Array(count)
    .fill(null)
    .map((_, id) =>
      createMergeRequest({
        id,
        props,
      }),
    );
};

export const createDefaultProjects = (count) => {
  return Array(count)
    .fill(null)
    .map((_, id) => ({
      id,
      name: `project-${id}`,
      fullPath: `group/project-${id}`,
    }));
};

export const createDefaultProjectsResponse = (projects) => ({
  data: {
    group: {
      id: '1',
      projects: {
        nodes: projects,
        __typename: 'Project',
      },
      __typename: 'Group',
    },
  },
});

export const createComplianceViolation = (id) => ({
  id: `gid://gitlab/MergeRequests::ComplianceViolation/${id}`,
  severityLevel: 'HIGH',
  reason: 'APPROVED_BY_COMMITTER',
  violatingUser: {
    id: 'gid://gitlab/User/21',
    name: 'Miranda Friesen',
    username: 'karren.medhurst',
    avatarUrl: 'https://www.gravatar.com/avatar/9102aef461ba77d0fa0f37daffb834ac?s=80&d=identicon',
    webUrl: 'http://gdk.test:3000/karren.medhurst',
    __typename: 'UserCore',
  },
  mergeRequest: {
    id: `gid://gitlab/MergeRequest/1`,
    title: `Merge request 1`,
    mergedAt: '2022-03-06T16:39:12Z',
    webUrl: 'http://gdk.test:3000/gitlab-org/gitlab-shell/-/merge_requests/56',
    author: {
      id: 'gid://gitlab/User/1',
      name: 'Administrator',
      username: 'root',
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      webUrl: 'http://gdk.test:3000/root',
      __typename: 'UserCore',
    },
    mergeUser: null,
    committers: {
      nodes: [],
      __typename: 'UserCoreConnection',
    },
    participants: {
      nodes: [
        {
          id: 'gid://gitlab/User/1',
          name: 'Administrator',
          username: 'root',
          avatarUrl:
            'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
          webUrl: 'http://gdk.test:3000/root',
          __typename: 'UserCore',
        },
      ],
      __typename: 'UserCoreConnection',
    },
    approvedBy: {
      nodes: [],
      __typename: 'UserCoreConnection',
    },
    ref: '!56',
    fullRef: 'gitlab-org/gitlab-shell!56',
    sourceBranch: 'master',
    sourceBranchExists: false,
    targetBranch: 'feature',
    targetBranchExists: false,
    project: {
      id: 'gid://gitlab/Project/2',
      avatarUrl: null,
      name: 'Gitlab Shell',
      webUrl: 'http://gdk.test:3000/gitlab-org/gitlab-shell',
      complianceFrameworks: {
        nodes: [
          {
            id: 'gid://gitlab/ComplianceManagement::Framework/1',
            name: 'GDPR',
            description: 'asds',
            color: '#0000ff',
            __typename: 'ComplianceFramework',
          },
        ],
        __typename: 'ComplianceFrameworkConnection',
      },
      __typename: 'Project',
    },
    __typename: 'MergeRequest',
  },
  __typename: 'ComplianceViolation',
});

export const createComplianceViolationsResponse = ({ count = 1, pageInfo = {} } = {}) => ({
  data: {
    group: {
      id: 'gid://gitlab/Group/1',
      __typename: 'Group',
      mergeRequestViolations: {
        __typename: 'ComplianceViolationConnection',
        nodes: Array(count)
          .fill(null)
          .map((_, id) => createComplianceViolation(id)),
        pageInfo: {
          endCursor: 'abc',
          hasNextPage: true,
          hasPreviousPage: false,
          startCursor: 'abc',
          __typename: 'PageInfo',
          ...pageInfo,
        },
      },
    },
  },
});
