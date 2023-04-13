import { merge } from 'lodash';

export const pipelineSecurityReportSummary = {
  data: {
    project: {
      id: 'project-1',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/99',
        securityReportSummary: {
          dast: {
            __typename: 'SecurityReportSummarySection',
            vulnerabilitiesCount: 5,
            scannedResourcesCsvPath:
              '/security/security-reports/-/security/scanned_resources.csv?pipeline_id=99',
            scans: {
              nodes: [{ name: 'dast', errors: [], warnings: [], status: 'SUCCEEDED' }],
            },
          },
          sast: {
            __typename: 'SecurityReportSummarySection',
            vulnerabilitiesCount: 67,
            scans: {
              nodes: [{ name: 'sast', errors: [], warnings: [], status: 'SUCCEEDED' }],
            },
          },
          containerScanning: {
            __typename: 'SecurityReportSummarySection',
            vulnerabilitiesCount: 2,
            scans: {
              nodes: [
                {
                  name: 'container-scanning',
                  errors: [],
                  warnings: [],
                  status: 'SUCCEEDED',
                },
              ],
            },
          },
          dependencyScanning: {
            __typename: 'SecurityReportSummarySection',
            vulnerabilitiesCount: 66,
            scans: {
              nodes: [
                {
                  name: 'dependency-scanning',
                  errors: [],
                  warnings: [],
                  status: 'SUCCEEDED',
                },
              ],
            },
          },
          apiFuzzing: {
            __typename: 'SecurityReportSummarySection',
            vulnerabilitiesCount: 6,
            scans: {
              nodes: [{ name: 'api-fuzzing', errors: [], warnings: [], status: 'SUCCEEDED' }],
            },
          },
          coverageFuzzing: {
            __typename: 'SecurityReportSummarySection',
            vulnerabilitiesCount: 1,
            scans: {
              nodes: [{ name: 'coverage-fuzzing', errors: [], warnings: [], status: 'SUCCEEDED' }],
            },
          },
          clusterImageScanning: {
            __typename: 'SecurityReportSummarySection',
            vulnerabilitiesCount: 2,
            scans: {
              nodes: [
                {
                  name: 'cluster-image-scanning',
                  errors: [],
                  warnings: [],
                  status: 'SUCCEEDED',
                },
              ],
            },
          },
          secretDetection: {
            __typename: 'SecurityReportSummarySection',
            vulnerabilitiesCount: 2,
            scans: {
              nodes: [
                {
                  name: 'secret-detection',
                  errors: [],
                  warnings: [],
                  status: 'SUCCEEDED',
                },
              ],
            },
          },
        },
        jobs: {
          nodes: [
            {
              id: 'job-1',
              name: 'api-fuzzing',
              artifacts: {
                nodes: [
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1038/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                  },
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1038/artifacts/download?file_type=api_fuzzing',
                    fileType: 'API_FUZZING',
                  },
                ],
              },
            },
            {
              id: 'job-2',
              name: 'coverage-fuzzing',
              artifacts: {
                nodes: [
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1037/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                  },
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1037/artifacts/download?file_type=coverage_fuzzing',
                    fileType: 'COVERAGE_FUZZING',
                  },
                ],
              },
            },
            {
              id: 'job-3',
              name: 'sast-tslint',
              artifacts: {
                nodes: [
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1036/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                  },
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1036/artifacts/download?file_type=sast',
                    fileType: 'SAST',
                  },
                ],
              },
            },
            {
              id: 'job-4',
              name: 'sast-spotbugs',
              artifacts: {
                nodes: [
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1035/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                  },
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1035/artifacts/download?file_type=sast',
                    fileType: 'SAST',
                  },
                ],
              },
            },
            {
              id: 'job-5',
              name: 'sast-sobelow',
              artifacts: {
                nodes: [
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1034/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                  },
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1034/artifacts/download?file_type=sast',
                    fileType: 'SAST',
                  },
                ],
              },
            },
            {
              id: 'job-6',
              name: 'sast-pmd-apex',
              artifacts: {
                nodes: [
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1033/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                  },
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1033/artifacts/download?file_type=sast',
                    fileType: 'SAST',
                  },
                ],
              },
            },
            {
              id: 'job-7',
              name: 'sast-eslint',
              artifacts: {
                nodes: [
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1032/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                  },
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1032/artifacts/download?file_type=sast',
                    fileType: 'SAST',
                  },
                ],
              },
            },
            {
              id: 'job-8',
              name: 'secrets',
              artifacts: {
                nodes: [
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1031/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                  },
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1031/artifacts/download?file_type=secret_detection',
                    fileType: 'SECRET_DETECTION',
                  },
                ],
              },
            },
            {
              id: 'job-9',
              name: 'dast',
              artifacts: {
                nodes: [
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1037/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                  },
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1037/artifacts/download?file_type=dast',
                    fileType: 'DAST',
                  },
                ],
              },
            },
            {
              id: 'job-10',
              name: 'dependency-scanning',
              artifacts: {
                nodes: [
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1039/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                  },
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1039/artifacts/download?file_type=dependency_scanning',
                    fileType: 'DEPENDENCY_SCANNING',
                  },
                ],
              },
            },
            {
              id: 'job-11',
              name: 'cluster-image-scanning',
              artifacts: {
                nodes: [
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1040/artifacts/download?file_type=trace',
                    fileType: 'TRACE',
                  },
                  {
                    downloadPath:
                      '/security/security-reports/-/jobs/1040/artifacts/download?file_type=cluster_image_scanning',
                    fileType: 'CLUSTER_IMAGE_SCANNING',
                  },
                ],
              },
            },
          ],
        },
      },
    },
  },
};

const purgedScan = {
  errors: ['error description'],
  warnings: [],
  name: 'scan-name',
  status: 'PURGED',
};

export const scansWithErrors = [
  { errors: ['error description'], warnings: [], name: 'scan-name', status: 'SUCCEEDED' },
];
export const scansWithWarnings = [
  { errors: [], warnings: ['warning description'], name: 'scan-name', status: 'SUCCEEDED' },
];

const getSecurityReportsSummaryMock = (nodes) => ({
  data: {
    project: {
      id: 'project-1',
      pipeline: {
        id: 'pipeline-1',
        securityReportSummary: {
          dast: {
            __typename: 'SecurityReportSummarySection',
            scans: {
              nodes,
            },
          },
        },
      },
    },
  },
});

export const purgedPipelineSecurityReportSummaryWithErrors = merge(
  {},
  pipelineSecurityReportSummary,
  getSecurityReportsSummaryMock(scansWithErrors.concat(purgedScan)),
);

export const purgedPipelineSecurityReportSummaryWithWarnings = merge(
  {},
  pipelineSecurityReportSummary,
  getSecurityReportsSummaryMock(scansWithWarnings.concat(purgedScan)),
);

export const pipelineSecurityReportSummaryWithErrors = merge(
  {},
  pipelineSecurityReportSummary,
  getSecurityReportsSummaryMock(scansWithErrors),
);

export const pipelineSecurityReportSummaryWithWarnings = merge(
  {},
  pipelineSecurityReportSummary,
  getSecurityReportsSummaryMock(scansWithWarnings),
);

export const pipelineSecurityReportSummaryEmpty = merge({}, pipelineSecurityReportSummary, {
  data: {
    project: {
      id: 'project-1',
      pipeline: {
        id: 'pipeline-1',
        securityReportSummary: {
          dast: null,
          sast: null,
          containerScanning: null,
          dependencyScanning: null,
          apiFuzzing: null,
          coverageFuzzing: null,
          clusterImageScanning: null,
          secretDetection: null,
        },
      },
    },
  },
});

export const vulnerabilityDetails = {
  url: {
    type: 'VulnerabilityDetailUrl',
    href: 'http://google.com',
    name: 'GitLab',
  },
  diff: {
    type: 'VulnerabilityDetailDiff',
    name: 'Code Diff',
    before: '<div>before</div>',
    after: '<div>after</div>',
  },
  code: {
    type: 'VulnerabilityDetailCode',
    name: 'vulnerable code snippet',
    value: '<h1>hello world</h1>',
  },
  commit: {
    type: 'VulnerabilityDetailCommit',
    name: 'Commit with vulnerability',
    value: '<h1>some vulnerable code</h1>',
  },
  moduleLocation: {
    type: 'VulnerabilityDetailModuleLocation',
    name: 'Vulnerable Module',
    moduleName: 'compiled binary',
    offset: 100,
  },
  fileLocation: {
    type: 'VulnerabilityDetailFileLocation',
    name: 'A vulnerable file',
    fileName: 'vulnerable.js',
    lineStart: '3',
    lineEnd: '5',
  },
  text: {
    type: 'VulnerabilityDetailText',
    name: 'Commit with vulnerability',
    value: 'text',
  },
  markdown: {
    type: 'VulnerabilityDetailMarkdown',
    name: 'Markdown value',
    value: '# heading',
  },
  boolean: {
    type: 'VulnerabilityDetailBoolean',
    name: 'Boolean value',
    value: 'true',
  },
  value: {
    type: 'VulnerabilityDetailValue',
    name: 'Boolean value',
    value: 'true',
  },
  int: {
    type: 'VulnerabilityDetailInt',
    name: 'Integer value',
    value: 'true',
  },
  list: {
    type: 'VulnerabilityDetailList',
    name: 'List',
    items: [],
  },
};

export const pipelineSecurityReportFinding = {
  uuid: '1',
  title: 'Vulnerability title',
  state: 'CONFIRMED',
  description: 'description',
  descriptionHtml: 'description <strong>html</strong>',
  severity: 'HIGH',
  solution: 'Some solution',
  reportType: 'reportType',
  falsePositive: false,
  mergeRequest: {
    id: '2',
    iid: 2,
    createdAt: '2022-10-16T22:42:02.975Z',
    webUrl: 'http://gdk.test:3000/secure-ex/security-reports/-/merge_requests/2',
    author: {
      __typename: 'UserCore',
      id: 'gid://gitlab/User/1',
      username: 'admin',
      name: 'Administrator',
      webUrl: 'http://gdk.test:3000/root',
    },
  },
  remediations: [
    {
      diff: 'SGVsbG8gR2l0TGFi',
      summary: 'Upgrade libcurl to 7.79.1-2.amzn2.0.1',
    },
  ],
  project: {
    id: '1',
    name: 'project name',
    webUrl: 'project fullName',
    nameWithNamespace: 'Secure Ex / Security Reports',
  },
  scanner: {
    id: '1',
    name: 'scanner name',
    url: 'http://example.com/scannerUrl',
    version: '1.0',
  },
  location: {
    class: 'location class',
    method: 'location method',
    crashAddress: 'location crashAddress',
    crashState: 'location crashState',
    crashType: 'location crashType',
    stackTraceSnippet: 'location stackTraceSnippet',
    file: 'location file',
    image: 'location image',
    operatingSystem: 'location operatingSystem',
  },
  issueLinks: {
    nodes: [],
  },
  evidence: {
    summary: 'Invalid status codes indicate an error.',
    request: {
      url: 'http://example.com/requestUrl',
      body: 'request body',
      method: 'request method',
      headers: [
        { name: 'headers name - 1', value: 'headers value - 1' },
        { name: 'headers name - 2', value: 'headers value - 2' },
      ],
    },
    response: {
      body: 'response body',
      statusCode: '200',
      reasonPhrase: 'response reasonPhrase',
      headers: [
        { name: 'response headers name - 1', value: 'response headers value - 1' },
        { name: 'response headers name - 2', value: 'response headers value - 2' },
      ],
    },
    supportingMessages: [
      {
        name: 'Recorded',
        response: {
          body: 'response body',
          statusCode: '200',
          reasonPhrase: 'response reasonPhrase',
          headers: [
            { name: 'response headers name - 1', value: 'response headers value - 1' },
            { name: 'response headers name - 2', value: 'response headers value - 2' },
          ],
        },
      },
    ],
    source: {
      name: 'Status Code',
    },
  },
  links: [
    { url: 'http://example.com/link-1', name: null },
    { url: 'http://example.com/link-2', name: 'links name - 1' },
  ],
  identifiers: [
    { url: 'http://example.com/identifier-1', name: 'identifiers name - 1' },
    { url: 'http://example.com/identifier-2', name: 'Identifiers name - 2' },
  ],
  evidenceSource: {
    name: 'evidenceSource name',
  },
  assets: [
    { url: 'http://example.com/asset-1', name: 'assets name - 1' },
    { url: 'http://example.com/asset-2', name: 'assets name - 2' },
  ],
  details: Object.values(vulnerabilityDetails),
  dismissedAt: null,
  dismissedBy: null,
  stateComment: null,
  vulnerability: {
    id: '1',
    userPermissions: {
      createVulnerabilityFeedback: true,
    },
  },
};

export const getPipelineSecurityReportFindingResponse = ({
  overrides = {},
  withoutFindingData = false,
} = {}) => ({
  data: {
    project: {
      id: '1',
      nameWithNamespace: 'Security / Security Reports',
      webUrl: 'http://gdk.test:3000/security/security-reports',
      pipeline: {
        id: '1',
        securityReportFinding: withoutFindingData
          ? null
          : { ...pipelineSecurityReportFinding, ...overrides },
      },
    },
  },
});

export const securityFindingDismissMutationResponse = {
  data: {
    securityFindingDismiss: {
      errors: [],
      securityFinding: {
        vulnerability: {
          id: 1,
          stateTransitions: {
            nodes: {
              author: null,
              comment: '',
              createdAt: '',
              toState: 'DISMISSED',
            },
          },
        },
      },
    },
  },
};

export const securityFindingRevertToDetectedMutationResponse = {
  data: {
    securityFindingRevertToDetected: {
      errors: [],
      securityFinding: {
        vulnerability: {
          id: 1,
          stateTransitions: {
            nodes: {
              author: null,
              comment: '',
              createdAt: '',
              toState: 'DETECTED',
            },
          },
        },
      },
    },
  },
};

export const securityFindingCreateMergeRequestMutationResponse = {
  data: {
    securityFindingCreateMergeRequest: {
      errors: [],
      mergeRequest: {
        id: '1',
        iid: '1',
        webUrl: 'https://gitlab.com',
      },
    },
  },
};

export const securityFindingCreateIssueMutationResponse = {
  data: {
    securityFindingCreateIssue: {
      errors: [],
      issue: {
        id: '1',
        webUrl: 'https://gitlab.com',
      },
    },
  },
};
