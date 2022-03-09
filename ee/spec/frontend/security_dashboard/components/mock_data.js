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
    resolvedOnDefaultBranch: true,
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
      nodes: [{ id: 'issue-1', issue: { id: 'issue-1', iid: 15 } }],
    },
    externalIssueLinks: {
      nodes: [{ id: 'issue-1', issue: { iid: 15, externalTracker: 'jira' } }],
    },
    __typename: 'Vulnerability',
  },
  {
    id: 'id_1',
    detectedAt: '2020-07-22T19:31:24Z',
    hasSolutions: false,
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
    scanner: {
      id: 'scanner-2',
      vendor: 'GitLab',
    },
    __typename: 'Vulnerability',
  },
  {
    id: 'id_2',
    detectedAt: '2020-08-22T20:00:12Z',
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
    __typename: 'Vulnerability',
  },
  {
    id: 'id_3',
    title: 'Vulnerability 3',
    severity: 'high',
    state: 'DETECTED',
    location: {
      file: 'yarn.lock',
    },
    project: {
      id: 'project-4',
      nameWithNamespace: 'Mixed Vulnerabilities / Rails App',
    },
    scanner: {},
    __typename: 'Vulnerability',
  },
  {
    id: 'id_4',
    title: 'Vulnerability 4',
    severity: 'critical',
    state: 'DISMISSED',
    location: {},
    project: {
      id: 'project-5',
      nameWithNamespace: 'Administrator / Security reports',
    },
    scanner: {},
    __typename: 'Vulnerability',
  },
  {
    id: 'id_5',
    title: 'Vulnerability 5',
    severity: 'high',
    state: 'DETECTED',
    location: {
      path: '/v1/trees',
    },
    project: {
      id: 'project-6',
      nameWithNamespace: 'Administrator / Security reports',
    },
    scanner: {},
    __typename: 'Vulnerability',
  },
];

export const vulnerabilities = generateVulnerabilities();
