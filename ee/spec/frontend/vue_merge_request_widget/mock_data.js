import mockData, { mockStore } from 'jest/vue_merge_request_widget/mock_data';

export default {
  ...mockData,
  can_read_vulnerabilities: true,
  enabled_reports: {
    sast: false,
    container_scanning: false,
    dast: false,
    dependency_scanning: false,
    license_management: false,
    secret_detection: false,
  },
  discover_project_security_path: '/discover_project_security',
  container_scanning_comparison_path: '/container_scanning_comparison_path',
  dependency_scanning_comparison_path: '/dependency_scanning_comparison_path',
  dast_comparison_path: '/dast_comparison_path',
  coverage_fuzzing_comparison_path: '/coverage_fuzzing_comparison_path',
  api_fuzzing_comparison_path: '/api_fuzzing_comparison_path',
};

// Browser Performance Testing
export const headBrowserPerformance = [
  {
    subject: '/some/path',
    metrics: [
      {
        name: 'Total Score',
        value: 80,
        desiredSize: 'larger',
      },
      {
        name: 'Requests',
        value: 30,
        desiredSize: 'smaller',
      },
      {
        name: 'Speed Index',
        value: 1155,
        desiredSize: 'smaller',
      },
      {
        name: 'Transfer Size (KB)',
        value: '1070.1',
        desiredSize: 'smaller',
      },
    ],
  },
];

export const baseBrowserPerformance = [
  {
    subject: '/some/path',
    metrics: [
      {
        name: 'Total Score',
        value: 82,
        desiredSize: 'larger',
      },
      {
        name: 'Requests',
        value: 30,
        desiredSize: 'smaller',
      },
      {
        name: 'Speed Index',
        value: 1165,
        desiredSize: 'smaller',
      },
      {
        name: 'Transfer Size (KB)',
        value: '1065.1',
        desiredSize: 'smaller',
      },
    ],
  },
];

// Load Performance Testing
export const headLoadPerformance = {
  metrics: {
    checks: {
      fails: 0,
      passes: 45,
      value: 0,
    },
    http_req_waiting: {
      avg: 104.3543911111111,
      max: 247.8693,
      med: 99.1985,
      min: 98.1397,
      'p(90)': 100.60016,
      'p(95)': 125.45588000000023,
    },
    http_reqs: {
      count: 45,
      rate: 8.999484329547917,
    },
  },
};

export const baseLoadPerformance = {
  metrics: {
    checks: {
      fails: 0,
      passes: 39,
      value: 0,
    },
    http_req_waiting: {
      avg: 118.28965641025643,
      max: 674.4383,
      med: 98.2503,
      min: 97.1357,
      'p(90)': 104.09862000000001,
      'p(95)': 101.22848,
    },
    http_reqs: {
      count: 39,
      rate: 7.799590989448514,
    },
  },
};

export const codequalityParsedIssues = [
  {
    name: 'Insecure Dependency',
    fingerprint: 'ca2e59451e98ae60ba2f54e3857c50e5',
    path: 'Gemfile.lock',
    line: 12,
    urlPath: 'foo/Gemfile.lock',
    severity: 'minor',
  },
];

export { mockStore };
