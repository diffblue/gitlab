import { cloneDeep } from 'lodash';
import { TEST_HOST } from 'helpers/test_constants';
import { WORKSPACE_DESIRED_STATES, WORKSPACE_STATES } from 'ee/remote_development/constants';

const WORKSPACE = {
  id: 1,
  name: 'Workspace 1',
  namespace: 'Namespace',
  projectId: 'gid://gitlab/Project/2',
  desiredState: 'Running',
  actualState: 'Started',
  url: `${TEST_HOST}/workspace/1`,
  devfileRef: 'main',
  devfilePath: '.devfile.yaml',
  createdAt: '2023-05-01T18:24:34Z',
};

export const WORKSPACE_QUERY_RESULT = {
  data: {
    workspace: cloneDeep(WORKSPACE),
  },
};

export const USER_WORKSPACES_QUERY_RESULT = {
  data: {
    currentUser: {
      id: 1,
      workspaces: {
        nodes: [
          {
            id: 'gid://gitlab/RemoteDevelopment::Workspace/2',
            name: 'workspace-1-1-idmi02',
            namespace: 'gl-rd-ns-1-1-idmi02',
            desiredState: 'Stopped',
            actualState: 'CreationRequested',
            url: 'https://8000-workspace-1-1-idmi02.workspaces.localdev.me?tkn=password',
            devfileRef: 'main',
            devfilePath: '.devfile.yaml',
            projectId: 'gid://gitlab/Project/2',
            createdAt: '2023-04-29T18:24:34Z',
          },
          {
            id: 'gid://gitlab/RemoteDevelopment::Workspace/1',
            name: 'workspace-1-1-rfu27q',
            namespace: 'gl-rd-ns-1-1-rfu27q',
            desiredState: 'Running',
            actualState: 'Running',
            url: 'https://8000-workspace-1-1-rfu27q.workspaces.localdev.me?tkn=password',
            devfileRef: 'main',
            devfilePath: '.devfile.yaml',
            projectId: 'gid://gitlab/Project/2',
            createdAt: '2023-05-01T18:24:34Z',
          },
        ],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
        },
      },
    },
  },
};

export const USER_WORKSPACES_QUERY_EMPTY_RESULT = {
  data: {
    currentUser: {
      id: 1,
      workspaces: {
        nodes: [],
        pageInfo: {
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
        },
      },
    },
  },
};

export const SEARCH_PROJECTS_QUERY_RESULT = {
  data: {
    projects: {
      nodes: [
        {
          id: 1,
          nameWithNamespace: 'GitLab Org / GitLab',
          fullPath: 'gitlab-org/gitlab',
          visibility: 'public',
        },
        {
          id: 2,
          nameWithNamespace: 'GitLab Org / GitLab Shell',
          fullPath: 'gitlab-org/gitlab-shell',
          visibility: 'public',
        },
      ],
    },
  },
};

export const GET_PROJECT_DETAILS_QUERY_RESULT = {
  data: {
    project: {
      id: 'gid://gitlab/Project/79',
      repository: {
        rootRef: 'main',
        blobs: {
          nodes: [
            { id: '.editorconfig', path: '.editorconfig' },
            { id: '.eslintrc.js', path: '.eslintrc.js' },
          ],
        },
      },
      group: {
        id: 'gid://gitlab/Group/80',
        fullPath: 'gitlab-org',
      },
    },
  },
};

export const GET_GROUP_CLUSTER_AGENTS_QUERY_RESULT = {
  data: {
    group: {
      id: 'gid://gitlab/Group/80',
      fullPath: 'gitlab-org',
      clusterAgents: {
        nodes: [
          {
            id: 'agents/1',
            name: 'default-agent',
            project: {
              id: 'gid://gitlab/Project/79',
              nameWithNamespace: 'GitLab Org / GitLab Shell',
            },
          },
        ],
      },
    },
  },
};

export const WORKSPACE_CREATE_MUTATION_RESULT = {
  data: {
    workspaceCreate: {
      errors: [],
      workspace: {
        ...cloneDeep(WORKSPACE),
        id: 2,
      },
    },
  },
};

export const WORKSPACE_UPDATE_MUTATION_RESULT = {
  data: {
    workspaceUpdate: {
      errors: [],
      workspace: {
        id: WORKSPACE.id,
        actualState: WORKSPACE_STATES.running,
        desiredState: WORKSPACE_DESIRED_STATES.restartRequested,
      },
    },
  },
};

export const USER_WORKSPACES_PROJECT_NAMES_QUERY_RESULT = {
  data: {
    projects: {
      nodes: [
        {
          id: 'gid://gitlab/Project/2',
          nameWithNamespace: 'Gitlab Org / Gitlab Shell',
          __typename: 'Project',
        },
      ],
      __typename: 'ProjectConnection',
    },
  },
};
