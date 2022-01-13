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
