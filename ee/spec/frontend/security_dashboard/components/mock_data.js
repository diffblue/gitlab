export const agentVulnerabilityImages = {
  data: {
    project: {
      id: 'gid://gitlab/Project/5000207',
      clusterAgent: {
        id: 'gid://gitlab/Clusters::Agent/1',
        vulnerabilityImages: {
          nodes: [
            {
              name: 'long-image-name',
              __typename: 'VulnerabilityContainerImage',
            },
          ],
          __typename: 'VulnerabilityContainerImageConnection',
        },

        __typename: 'ClusterAgent',
      },
      __typename: 'Project',
    },
  },
};

export const projectVulnerabilityImages = {
  data: {
    project: {
      id: 'gid://gitlab/Project/5000207',
      vulnerabilityImages: {
        nodes: [
          {
            name: 'long-image-name',
            __typename: 'VulnerabilityContainerImage',
          },
          {
            name: 'second-long-image-name',
            __typename: 'VulnerabilityContainerImage',
          },
        ],
        __typename: 'VulnerabilityContainerImageConnection',
      },
      __typename: 'Project',
    },
  },
};

export const projectClusters = {
  data: {
    project: {
      id: 'gid://gitlab/Project/5000207',
      clusterAgents: {
        nodes: [
          {
            id: 'gid://gitlab/Clusters::Agent/2',
            name: 'primary-agent',
            __typename: 'ClusterAgentConnection',
          },
        ],
        __typename: 'ClusterAgentConnection',
      },
      __typename: 'Project',
    },
  },
};

export const clusterImageScanningVulnerability = {
  hasSolutions: null,
  mergeRequest: null,
  __typename: 'Vulnerability',
  id: 'gid://gitlab/Vulnerability/22087293',
  title: 'CVE-2021-29921',
  state: 'DETECTED',
  severity: 'CRITICAL',
  detectedAt: '2021-11-04T20:01:14Z',
  vulnerabilityPath:
    '/gitlab-org/protect/demos/agent-cluster-image-scanning-demo/-/security/vulnerabilities/22087293',
  resolvedOnDefaultBranch: false,
  userNotesCount: 0,
  falsePositive: false,
  issueLinks: {
    nodes: [],
    __typename: 'VulnerabilityIssueLinkConnection',
  },
  identifiers: [
    {
      externalType: 'cve',
      name: 'CVE-2021-29921',
      __typename: 'VulnerabilityIdentifier',
    },
  ],
  location: {
    __typename: 'VulnerabilityLocationClusterImageScanning',
    kubernetesResource: {
      agent: {
        name: 'cis-demo',
        webPath:
          '/gitlab-org/protect/demos/agent-cluster-image-scanning-demo/-/cluster_agents/cis-demo',
        __typename: 'ClusterAgent',
      },
      __typename: 'VulnerableKubernetesResource',
    },
  },
};

export const generateVulnerabilities = () => [
  {
    id: 'id_0',
    detectedAt: '2020-07-29T15:36:54Z',
    hasSolutions: true,
    mergeRequest: {
      id: 'mr-1',
      webUrl: 'www.testmr.com/1',
      state: 'status_warning',
      securityAutoFix: true,
      iid: 1,
    },
    identifiers: [
      {
        externalType: 'cve',
        name: 'CVE-2018-1234',
      },
      {
        externalType: 'gemnasium',
        name: 'Gemnasium-2018-1234',
      },
    ],
    title: 'Vulnerability 0',
    severity: 'critical',
    state: 'DISMISSED',
    reportType: 'SAST',
    resolvedOnDefaultBranch: false,
    location: {
      image:
        'registry.gitlab.com/groulot/container-scanning-test/main:5f21de6956aee99ddb68ae49498662d9872f50ff',
    },
    project: {
      id: 'project-1',
      nameWithNamespace: 'Administrator / Security reports',
    },
    scanner: {
      id: 'scanner-1',
      vendor: 'GitLab',
    },
    issueLinks: {
      nodes: [
        {
          id: 'issue-1',
          issue: {
            id: 'issue-1',
            iid: 15,
            webUrl: 'url',
            webPath: 'path',
            title: 'title',
            state: 'state',
            resolvedOnDefaultBranch: true,
          },
        },
      ],
    },
    externalIssueLinks: {
      nodes: [
        {
          id: 'issue-1',
          issue: { iid: 15, externalTracker: 'jira', resolvedOnDefaultBranch: true },
        },
      ],
    },
    vulnerabilityPath: 'path',
    userNotesCount: 1,
    __typename: 'Vulnerability',
  },
  {
    id: 'id_1',
    detectedAt: '2020-07-22T19:31:24Z',
    resolvedOnDefaultBranch: false,
    hasSolutions: false,
    issueLinks: [],
    identifiers: [
      {
        externalType: 'gemnasium',
        name: 'Gemnasium-2018-1234',
      },
    ],
    title: 'Vulnerability 1',
    severity: 'high',
    state: 'DETECTED',
    reportType: 'DEPENDENCY_SCANNING',
    location: {
      file: 'src/main/java/com/gitlab/security_products/tests/App.java',
      startLine: '1337',
      blobPath:
        '/gitlab-org/security-reports2/-/blob/e5c61e4d5d0b8418011171def04ca0aa36532621/src/main/java/com/gitlab/security_products/tests/App.java',
    },
    project: {
      id: 'project-2',
      nameWithNamespace: 'Administrator / Vulnerability reports',
    },
    scanner: { id: 'scanner-2', vendor: 'GitLab' },
    vulnerabilityPath: '#',
    userNotesCount: 0,
    __typename: 'Vulnerability',
  },
  {
    id: 'id_2',
    detectedAt: '2020-08-22T20:00:12Z',
    resolvedOnDefaultBranch: false,
    issueLinks: [],
    identifiers: [],
    title: 'Vulnerability 2',
    severity: 'high',
    state: 'DETECTED',
    reportType: 'CUSTOM_SCANNER_WITHOUT_TRANSLATION',
    location: {
      file: 'src/main/java/com/gitlab/security_products/tests/App.java',
    },
    project: {
      id: 'project-3',
      nameWithNamespace: 'Mixed Vulnerabilities / Dependency List Test 01',
    },
    scanner: {
      id: 'scanner-3',
      vendor: 'My Custom Scanner',
    },
    vulnerabilityPath: 'path',
    userNotesCount: 2,
    __typename: 'Vulnerability',
  },
  {
    id: 'id_3',
    title: 'Vulnerability 3',
    detectedAt: new Date(),
    resolvedOnDefaultBranch: true,
    issueLinks: [],
    identifiers: [],
    reportType: '',
    severity: 'high',
    state: 'DETECTED',
    location: {
      file: 'yarn.lock',
    },
    project: {
      id: 'project-4',
      nameWithNamespace: 'Mixed Vulnerabilities / Rails App',
    },
    scanner: { id: 'scanner-3', vendor: '' },
    vulnerabilityPath: 'path',
    userNotesCount: 3,
    __typename: 'Vulnerability',
  },
  {
    id: 'id_4',
    title: 'Vulnerability 4',
    severity: 'critical',
    state: 'DISMISSED',
    detectedAt: new Date(),
    resolvedOnDefaultBranch: true,
    issueLinks: [],
    identifiers: [],
    reportType: 'DAST',
    location: {},
    project: {
      id: 'project-5',
      nameWithNamespace: 'Administrator / Security reports',
    },
    scanner: { id: 'scanner-4', vendor: 'GitLab' },
    vulnerabilityPath: 'path',
    userNotesCount: 4,
    __typename: 'Vulnerability',
  },
  {
    id: 'id_5',
    title: 'Vulnerability 5',
    severity: 'high',
    state: 'DETECTED',
    detectedAt: new Date(),
    resolvedOnDefaultBranch: false,
    issueLinks: [],
    identifiers: [],
    reportType: 'DEPENDENCY_SCANNING',
    location: {
      path: '/v1/trees',
    },
    project: {
      id: 'project-6',
      nameWithNamespace: 'Administrator / Security reports',
    },
    scanner: { id: 'scanner-5', vendor: 'GitLab' },
    vulnerabilityPath: 'path',
    userNotesCount: 5,
    __typename: 'Vulnerability',
  },
  {
    id: 'id_6',
    title: 'Vulnerability 6',
    severity: 'high',
    state: 'DETECTED',
    detectedAt: new Date(),
    resolvedOnDefaultBranch: false,
    issueLinks: [],
    identifiers: [],
    reportType: 'DEPENDENCY_SCANNING',
    location: {
      path: '/v1/trees',
      file: 'yarn.lock',
    },
    project: {
      id: 'project-6',
      nameWithNamespace: 'Administrator / Security reports',
    },
    scanner: { id: 'scanner-5', vendor: 'GitLab' },
    vulnerabilityPath: 'path',
    userNotesCount: 5,
    __typename: 'Vulnerability',
  },
];

export const vulnerabilities = generateVulnerabilities();

const generateVulnerabilityScanners = () => [
  {
    id: 'gid://gitlab/Vulnerabilities::Scanner/155',
    externalId: 'eslint',
    name: 'ESLint',
    vendor: 'GitLab',
    reportType: 'SAST',
    __typename: 'VulnerabilityScanner',
  },
  {
    id: 'gid://gitlab/Vulnerabilities::Scanner/156',
    externalId: 'find_sec_bugs',
    name: 'Find Security Bugs',
    vendor: 'GitLab',
    reportType: 'SAST',
    __typename: 'VulnerabilityScanner',
  },
  {
    id: 'gid://gitlab/Vulnerabilities::Scanner/247',
    externalId: 'gitlab-manual-vulnerability-report',
    name: 'manually-created-vulnerability',
    vendor: 'GitLab',
    reportType: 'GENERIC',
    __typename: 'VulnerabilityScanner',
  },
];

export const projectVulnerabilityScanners = {
  data: {
    project: {
      id: 'gid://gitlab/Project/26',
      vulnerabilityScanners: {
        nodes: generateVulnerabilityScanners(),
      },
    },
  },
};

export const groupVulnerabilityScanners = {
  data: {
    group: {
      id: 'gid://gitlab/Group/22',
      vulnerabilityScanners: {
        nodes: generateVulnerabilityScanners(),
      },
    },
  },
};

export const instanceVulnerabilityScanners = {
  data: {
    instanceSecurityDashboard: {
      vulnerabilityScanners: {
        nodes: generateVulnerabilityScanners(),
      },
    },
  },
};
