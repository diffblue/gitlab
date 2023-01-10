import { merge } from 'lodash';

export const pipelineSecurityReportSummary = {
  data: {
    project: {
      id: 'project-1',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/99',
        securityReportSummary: {
          dast: {
            vulnerabilitiesCount: 5,
            scannedResourcesCsvPath:
              '/security/security-reports/-/security/scanned_resources.csv?pipeline_id=99',
            scans: {
              nodes: [{ name: 'dast', errors: [] }],
            },
          },
          sast: {
            vulnerabilitiesCount: 67,
            scans: {
              nodes: [{ name: 'sast', errors: [] }],
            },
          },
          containerScanning: {
            vulnerabilitiesCount: 2,
            scans: {
              nodes: [
                {
                  name: 'container-scanning',
                  errors: [],
                },
              ],
            },
          },
          dependencyScanning: {
            vulnerabilitiesCount: 66,
            scans: {
              nodes: [
                {
                  name: 'dependency-scanning',
                  errors: [],
                },
              ],
            },
          },
          apiFuzzing: {
            vulnerabilitiesCount: 6,
            scans: {
              nodes: [{ name: 'api-fuzzing', errors: [] }],
            },
          },
          coverageFuzzing: {
            vulnerabilitiesCount: 1,
            scans: {
              nodes: [{ name: 'coverage-fuzzing', errors: [] }],
            },
          },
          clusterImageScanning: {
            vulnerabilitiesCount: 2,
            scans: {
              nodes: [
                {
                  name: 'cluster-image-scanning',
                  errors: [],
                },
              ],
            },
          },
          secretDetection: {
            vulnerabilitiesCount: 2,
            scans: {
              nodes: [
                {
                  name: 'secret-detection',
                  errors: [],
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
        securityReportSummary: null,
      },
    },
  },
});

export const pipelineSecurityReportFinding = {
  uuid: '1',
  title: 'Vulnerability title',
  state: 'CONFIRMED',
  description: 'description',
  severity: 'HIGH',
  solution: 'Some solution',
  reportType: 'reportType',
  falsePositive: false,
  project: {
    id: '1',
    name: 'project name',
    webUrl: 'project fullName',
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
  evidence: 'evidence',
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
};

export const getPipelineSecurityReportFindingResponse = (withoutFindingData = false) => ({
  data: {
    project: {
      id: '1',
      pipeline: {
        id: '1',
        securityReportFinding: withoutFindingData ? null : pipelineSecurityReportFinding,
      },
    },
  },
});
