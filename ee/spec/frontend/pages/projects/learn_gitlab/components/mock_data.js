import { DOCS_URL_IN_EE_DIR } from 'jh_else_ce/lib/utils/url_utility';

export const testActions = {
  codeAdded: {
    url: 'http://example.com/',
    completed: true,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
  },
  gitWrite: {
    url: 'http://example.com/',
    completed: true,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
  },
  userAdded: {
    url: 'http://example.com/',
    completed: true,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
  },
  pipelineCreated: {
    url: 'http://example.com/',
    completed: false,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
  },
  trialStarted: {
    url: 'http://example.com/',
    completed: false,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
  },
  codeOwnersEnabled: {
    url: 'http://example.com/',
    completed: false,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
  },
  requiredMrApprovalsEnabled: {
    url: 'http://example.com/',
    completed: false,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
  },
  mergeRequestCreated: {
    url: 'http://example.com/',
    completed: false,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
  },
  licenseScanningRun: {
    url: `${DOCS_URL_IN_EE_DIR}/foobar/`,
    completed: false,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
    openInNewTab: true,
  },
  secureDependencyScanningRun: {
    url: `${DOCS_URL_IN_EE_DIR}/foobar/`,
    completed: false,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
    openInNewTab: true,
  },
  secureDastRun: {
    url: `${DOCS_URL_IN_EE_DIR}/foobar/`,
    completed: false,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
    openInNewTab: true,
  },
  issueCreated: {
    url: 'http://example.com/',
    completed: false,
    svg: 'http://example.com/images/illustration.svg',
    enabled: true,
  },
};

export const testSections = [
  {
    code: {
      svg: 'code.svg',
    },
  },
  {
    workspace: {
      svg: 'workspace.svg',
    },
    deploy: {
      svg: 'deploy.svg',
    },
    plan: {
      svg: 'plan.svg',
    },
  },
];

export const testProject = {
  name: 'test-project',
};
