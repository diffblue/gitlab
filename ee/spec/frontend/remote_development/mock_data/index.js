import { cloneDeep } from 'lodash';
import { TEST_HOST } from 'helpers/test_constants';

const WORKSPACE = {
  id: 1,
  name: 'Workspace 1',
  namespace: 'Namespace',
  projectFullPath: 'GitLab.org / GitLab',
  desiredState: 'Running',
  actualState: 'Started',
  displayedState: 'Started',
  url: `${TEST_HOST}/workspace/1`,
  editor: 'VSCode',
  devfile: 'devfile',
  branch: 'master',
  lastUsed: '2020-01-01T00:00:00.000Z',
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
            actualState: 'Creating',
            url: 'http://8000-workspace-1-1-idmi02.workspaces.localdev.me?tkn=password',
            devfileRef: 'main',
            devfilePath: '.devfile.yaml',
            project: {
              id: 'gid://gitlab/Project/2',
              nameWithNamespace: 'Gitlab Shell',
            },
          },
          {
            id: 'gid://gitlab/RemoteDevelopment::Workspace/1',
            name: 'workspace-1-1-rfu27q',
            namespace: 'gl-rd-ns-1-1-rfu27q',
            desiredState: 'Running',
            actualState: 'Running',
            url: 'http://8000-workspace-1-1-rfu27q.workspaces.localdev.me?tkn=password',
            devfileRef: 'main',
            devfilePath: '.devfile.yaml',
            project: {
              id: 'gid://gitlab/Project/2',
              nameWithNamespace: 'Gitlab Shell',
            },
          },
        ],
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
      },
    },
  },
};

export const CURRENT_USERNAME = 'root';

export const SEARCH_PROJECTS_QUERY_RESULT = {
  data: {
    projects: {
      nodes: [
        {
          id: 1,
          nameWithNamespace: 'GitLab Org / GitLab',
          fullPath: 'gitlab-org/gitlab',
        },
        {
          id: 2,
          nameWithNamespace: 'GitLab Org / GitLab Shell',
          fullPath: 'gitlab-org/gitlab-shell',
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
      clusterAgents: { nodes: [{ name: 'default-agent', id: 'agents/1' }] },
    },
  },
};

export const WORKSPACE_CREATE_MUTATION_RESULT = {
  data: {
    workspaceCreate: {
      errors: [],
    },
  },
};
