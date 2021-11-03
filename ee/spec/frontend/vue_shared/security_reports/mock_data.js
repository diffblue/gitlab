import { mockFindings } from 'jest/vue_shared/security_reports/mock_data';

export * from 'jest/vue_shared/security_reports/mock_data';

const libTiffCveFingerprint2 = '29af456d1107381bc2511646e2ae488ddfe9a8ed';

export const sastParsedIssues = [
  {
    title: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    line: 12,
    severity: 'high',
    urlPath: 'foo/Gemfile.lock',
    report_type: 'sast',
  },
];

export const licenseComplianceParsedIssues = [
  {
    name: 'New BSD',
    dependencies: [
      { name: 'pg', version: null, package_manager: null, blob_path: null },
      { name: 'puma', version: null, package_manager: null, blob_path: null },
    ],
    url: 'http://opensource.org/licenses/BSD-3-Clause',
    classification: { id: null, name: 'New BSD', approval_status: 'unclassified' },
    count: 2,
    approvalStatus: 'unclassified',
    id: null,
    packages: [
      { name: 'pg', version: null, package_manager: null, blob_path: null },
      { name: 'puma', version: null, package_manager: null, blob_path: null },
    ],
    status: 'neutral',
  },
];

export const dependencyScanningIssues = [
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Cross-site Scripting in serialize-javascript',
    description:
      'The serialize-javascript npm package is vulnerable to Cross-site Scripting (XSS). It does not properly mitigate against unsafe characters in serialized regular expressions. If serialized data of regular expression objects are used in an environment other than Node.js, it is affected by this vulnerability.',
    links: [{ url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-16769' }],
    location: {
      file: 'yarn.lock',
      dependency: { package: { name: 'serialize-javascript' }, version: '1.7.0' },
    },
    path: 'yarn.lock',
  },
];

export const dockerReportParsed = {
  unapproved: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'medium',
      title: 'CVE-2017-12944',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-12944',
          value: 'CVE-2017-12944',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-12944',
        },
      ],
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'low',
      title: 'CVE-2017-16232',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-16232',
          value: 'CVE-2017-16232',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
        },
      ],
    },
  ],
  approved: [
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'low',
      title: 'CVE-2014-8130',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-8130',
          value: 'CVE-2017-8130',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8130',
        },
      ],
    },
  ],
  vulnerabilities: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'medium',
      title: 'CVE-2017-12944',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-12944',
          value: 'CVE-2017-12944',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-v',
        },
      ],
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'low',
      title: 'CVE-2017-16232',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-16232',
          value: 'CVE-2017-16232',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
        },
      ],
    },
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'low',
      title: 'CVE-2014-8130',
      path: 'debian:8',
      identifiers: [
        {
          type: 'CVE',
          name: 'CVE-2017-8130',
          value: 'CVE-2017-8130',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8130',
        },
      ],
    },
  ],
};

export const parsedDast = [
  {
    category: 'dast',
    project_fingerprint: '40bd001563085fc35165329ea1ff5c5ecbdbbeef',
    name: 'Absence of Anti-CSRF Tokens',
    title: 'Absence of Anti-CSRF Tokens',
    riskcode: '1',
    riskdesc: 'Low (Medium)',
    severity: 'low',
    cweid: '3',
    desc: '<p>No Anti-CSRF tokens were found in a HTML submission form.</p>',
    pluginid: '123',
    identifiers: [
      {
        type: 'CWE',
        name: 'CWE-3',
        value: '3',
        url: 'https://cwe.mitre.org/data/definitions/3.html',
      },
    ],
    instances: [
      {
        uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
        method: 'GET',
        evidence: "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
      },
      {
        uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
        method: 'GET',
        evidence: "<form class='form-inline' action='/search' accept-charset='UTF-8' method='get'>",
      },
    ],
    solution: ' Update to latest ',
    description: ' No Anti-CSRF tokens were found in a HTML submission form. ',
  },
  {
    category: 'dast',
    project_fingerprint: 'ae8fe380dd9aa5a7a956d9085fe7cf6b87d0d028',
    alert: 'X-Content-Type-Options Header Missing',
    name: 'X-Content-Type-Options Header Missing',
    title: 'X-Content-Type-Options Header Missing',
    riskdesc: 'Low (Medium)',
    identifiers: [
      {
        type: 'CWE',
        name: 'CWE-4',
        value: '4',
        url: 'https://cwe.mitre.org/data/definitions/4.html',
      },
    ],
    severity: 'low',
    cweid: '4',
    desc: '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
    pluginid: '3456',
    instances: [
      {
        uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
        method: 'GET',
        param: 'X-Content-Type-Options',
      },
    ],
    solution: ' Update to latest ',
    description: ' The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". ',
  },
];

export const secretDetectionParsedIssues = [
  {
    title: 'AWS SecretKey detected',
    path: 'Gemfile.lock',
    line: 12,
    severity: 'critical',
    urlPath: 'foo/Gemfile.lock',
  },
];

export const dependencyScanningFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'dependency_scanning',
    feedback_type: 'dismissal',
    branch: 'try_new_container_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'dependency_scanning',
    feedback_type: 'issue',
    branch: 'try_new_container_scanning',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
];

export const dastFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'dismissal',
    branch: 'try_new_container_scanning',
    project_fingerprint: '40bd001563085fc35165329ea1ff5c5ecbdbbeef',
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'issue',
    branch: 'try_new_container_scanning',
    project_fingerprint: '40bd001563085fc35165329ea1ff5c5ecbdbbeef',
  },
];

export const containerScanningFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'dismissal',
    branch: 'try_new_container_scanning',
    project_fingerprint: libTiffCveFingerprint2,
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'container_scanning',
    feedback_type: 'issue',
    branch: 'try_new_container_scanning',
    project_fingerprint: libTiffCveFingerprint2,
  },
];

export const coverageFuzzingFeedbacks = [
  {
    id: 3,
    project_id: 17,
    author_id: 1,
    issue_iid: null,
    pipeline_id: 132,
    category: 'coverage_fuzzing',
    feedback_type: 'dismissal',
    branch: 'try_new_coverage_fuzzing',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
  {
    id: 4,
    project_id: 17,
    author_id: 1,
    issue_iid: 123,
    pipeline_id: 132,
    category: 'coverage_fuzzing',
    feedback_type: 'issue',
    branch: 'try_new_coverage_fuzzing',
    project_fingerprint: 'f55331d66fd4f3bfb4237d48e9c9fa8704bd33c6',
  },
];

export const dastDiffSuccessMock = {
  added: [mockFindings[0]],
  fixed: [mockFindings[1], mockFindings[2]],
  base_report_created_at: '2020-01-01T10:00:00.000Z',
  base_report_out_of_date: false,
  head_report_created_at: '2020-01-10T10:00:00.000Z',
};

export const containerScanningDiffSuccessMock = {
  added: [mockFindings[0], mockFindings[1]],
  fixed: [mockFindings[2]],
  base_report_created_at: '2020-01-01T10:00:00.000Z',
  base_report_out_of_date: false,
  head_report_created_at: '2020-01-10T10:00:00.000Z',
};

export const dependencyScanningDiffSuccessMock = {
  added: [mockFindings[0], mockFindings[1]],
  fixed: [mockFindings[2]],
  base_report_created_at: '2020-01-01T10:00:00.000Z',
  base_report_out_of_date: false,
  head_report_created_at: '2020-01-10T10:00:00.000Z',
};

export const coverageFuzzingDiffSuccessMock = {
  added: [mockFindings[0], mockFindings[1]],
  fixed: [mockFindings[2]],
  base_report_created_at: '2020-01-01T10:00:00.000Z',
  base_report_out_of_date: false,
  head_report_created_at: '2020-01-10T10:00:00.000Z',
};

export const apiFuzzingDiffSuccessMock = {
  added: [mockFindings[0], mockFindings[1]],
  fixed: [mockFindings[2]],
  base_report_created_at: '2020-01-01T10:00:00.000Z',
  base_report_out_of_date: false,
  head_report_created_at: '2020-01-10T10:00:00.000Z',
};
