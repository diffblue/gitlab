export const mockProjectsWithSeverityCounts = () => [
  {
    id: 'gid://gitlab/Project/1',
    name: 'Gitlab Test',
    nameWithNamespace: 'Gitlab Org / Gitlab Test',
    securityDashboardPath: '/gitlab-org/gitlab-test/-/security/dashboard',
    fullPath: 'gitlab-org/gitlab-test',
    avatarUrl: null,
    path: 'gitlab-test',
    vulnerabilitySeveritiesCount: {
      critical: 2,
      high: 0,
      info: 4,
      low: 3,
      medium: 0,
      unknown: 1,
    },
  },
  {
    id: 'gid://gitlab/Project/2',
    name: 'Gitlab Shell',
    nameWithNamespace: 'Gitlab Org / Gitlab Shell',
    securityDashboardPath: '/gitlab-org/gitlab-shell/-/security/dashboard',
    fullPath: 'gitlab-org/gitlab-shell',
    avatarUrl: null,
    path: 'gitlab-shell',
    vulnerabilitySeveritiesCount: {
      critical: 0,
      high: 2,
      info: 2,
      low: 1,
      medium: 1,
      unknown: 2,
    },
  },
  {
    id: 'gid://gitlab/Project/4',
    name: 'Gitlab Perfectly Secure',
    nameWithNamespace: 'Gitlab Org / Perfectly Secure',
    securityDashboardPath: '/gitlab-org/gitlab-perfectly-secure/-/security/dashboard',
    fullPath: 'gitlab-org/gitlab-perfectly-secure',
    avatarUrl: null,
    path: 'gitlab-perfectly-secure',
    vulnerabilitySeveritiesCount: {
      critical: 0,
      high: 0,
      info: 0,
      low: 0,
      medium: 0,
      unknown: 0,
    },
  },
  {
    id: 'gid://gitlab/Project/5',
    name: 'Gitlab Perfectly Secure 2 ',
    nameWithNamespace: 'Gitlab Org / Perfectly Secure 2',
    securityDashboardPath: '/gitlab-org/gitlab-perfectly-secure-2/-/security/dashboard',
    fullPath: 'gitlab-org/gitlab-perfectly-secure-2',
    avatarUrl: null,
    path: 'gitlab-perfectly-secure-2',
    vulnerabilitySeveritiesCount: {
      critical: 0,
      high: 0,
      info: 0,
      low: 0,
      medium: 0,
      unknown: 0,
    },
  },
];

const projectsMemoized = mockProjectsWithSeverityCounts();
const vulnerabilityGrades = [
  {
    grade: 'F',
    count: 1,
    projects: {
      nodes: [projectsMemoized[0]],
    },
  },
  {
    grade: 'D',
    count: 1,
    projects: {
      nodes: [projectsMemoized[1]],
    },
  },
  {
    grade: 'C',
    count: 2,
    projects: {
      nodes: [projectsMemoized[0], projectsMemoized[1]],
    },
  },
  {
    grade: 'B',
    count: 1,
    projects: {
      nodes: [projectsMemoized[1]],
    },
  },
  {
    grade: 'A',
    count: 3,
    projects: {
      nodes: [projectsMemoized[2], projectsMemoized[3]],
    },
  },
];

export const mockGroupVulnerabilityGrades = () => ({
  data: {
    group: {
      id: 'group-1',
      vulnerabilityGrades,
    },
  },
});

export const mockInstanceVulnerabilityGrades = () => ({
  data: {
    instanceSecurityDashboard: {
      vulnerabilityGrades,
    },
  },
});

export const mockProjectSecurityChartsWithoutData = () => ({
  data: {
    project: {
      vulnerabilitiesCountByDay: {
        edges: [],
      },
    },
  },
});

export const mockProjectSecurityChartsWithData = () => ({
  data: {
    project: {
      id: 'project-1',
      vulnerabilitiesCountByDay: {
        nodes: [
          {
            date: '2020-07-22',
            critical: 4,
            high: 3,
            info: 2,
            low: 10,
            medium: 2,
            unknown: 1,
          },
          {
            date: '2020-07-23',
            critical: 2,
            high: 3,
            info: 2,
            low: 10,
            medium: 2,
            unknown: 1,
          },
          {
            date: '2020-07-24',
            critical: 2,
            high: 3,
            info: 2,
            low: 10,
            medium: 2,
            unknown: 1,
          },
          {
            date: '2020-07-25',
            critical: 2,
            high: 3,
            info: 2,
            low: 10,
            medium: 2,
            unknown: 1,
          },
          {
            date: '2020-07-26',
            critical: 2,
            high: 3,
            info: 2,
            low: 10,
            medium: 2,
            unknown: 1,
          },
          {
            date: '2020-07-27',
            critical: 2,
            high: 3,
            info: 2,
            low: 10,
            medium: 2,
            unknown: 1,
          },
        ],
      },
    },
  },
});

export const mockVulnerableProjectsInstance = () => ({
  data: {
    instance: {
      projects: {
        nodes: [
          {
            id: 'gid://gitlab/Project/2',
            name: 'Gitlab Shell',
            nameWithNamespace: 'Group / Gitlab Shell',
          },
        ],
      },
    },
  },
});

export const mockVulnerableProjectsGroup = () => ({
  data: {
    group: {
      id: 'group-1',
      projects: {
        nodes: [
          {
            id: 'gid://gitlab/Project/2',
            name: 'Gitlab Shell',
          },
        ],
      },
    },
  },
});

export const mockVulnerabilitySeveritiesGraphQLResponse = ({ dashboardType }) => ({
  data: {
    [dashboardType]: {
      id: '1',
      vulnerabilitySeveritiesCount: {
        __typename: 'VulnerabilitySeveritiesCount',
        critical: 0,
        high: 0,
        info: 0,
        low: 0,
        medium: 4,
        unknown: 2,
      },
    },
    __typename: { project: 'Project', instance: 'InstanceSecurityDashboard', group: 'Group' }[
      dashboardType
    ],
  },
});

export const mockPipelineFindingsResponse = ({ hasNextPage } = {}) => ({
  data: {
    project: {
      id: 'project-1',
      pipeline: {
        id: 'gid://gitlab/Ci::Pipeline/59',
        securityReportFindings: {
          nodes: [
            {
              uuid: '322ace94-2d2a-5efa-bd62-a04c927a4b9a',
              name: 'growl_command-injection in growl',
              description: null,
              confidence: 'unknown',
              identifiers: [
                {
                  externalType: 'npm',
                  name: 'NPM-146',
                  __typename: 'VulnerabilityIdentifier',
                },
              ],
              scanner: null,
              severity: 'HIGH',
              state: 'DETECTED',
              solution: 'Upgrade to versions 5.2.2.1, 6.0.0 or above.',
              reportType: 'DEPENDENCY_SCANNING',
              location: {
                __typename: 'VulnerabilityLocationDependencyScanning',
                blobPath: null,
                file: 'package.json',
                image: null,
                startLine: null,
                path: null,
              },
              __typename: 'PipelineSecurityReportFinding',
            },
            {
              uuid: '31ad79c6-b545-5408-89af-c4e90fc21eb4',
              name:
                'A prototype pollution vulnerability in handlebars may lead to remote code execution if an attacker can control the template in handlebars',
              description: null,
              confidence: 'unknown',
              state: 'RESOLVED',
              identifiers: [
                {
                  externalType: 'retire.js',
                  name: 'RETIRE-JS-baf1b2b5f9a7c1dc0fb152365126e6c3',
                  __typename: 'VulnerabilityIdentifier',
                },
              ],
              scanner: null,
              severity: 'HIGH',
              reportType: 'DEPENDENCY_SCANNING',
              solution: 'Upgrade to versions 5.2.2.1, 6.0.0 or above.',
              location: {
                __typename: 'VulnerabilityLocationDependencyScanning',
                blobPath: null,
                file: 'package.json',
                image: null,
                startLine: null,
                path: null,
              },
              __typename: 'PipelineSecurityReportFinding',
            },
          ],
          pageInfo: {
            __typename: 'PageInfo',
            startCursor: 'MQ',
            endCursor: hasNextPage ? 'MjA' : false,
          },
          __typename: 'PipelineSecurityReportFindingConnection',
        },
        __typename: 'Pipeline',
      },
      __typename: 'Project',
    },
  },
});
