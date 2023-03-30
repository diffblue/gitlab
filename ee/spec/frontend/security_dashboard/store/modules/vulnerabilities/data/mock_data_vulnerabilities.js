const issueData = {
  id: 2,
  project_id: 1,
  author: {
    id: 8,
    name: 'John Doe9',
    username: 'user8',
    state: 'active',
    avatar_url: 'https://www.gravatar.com/avatar/51798cfc94af924ac2dffb7083baa6f4?s=80&d=identicon',
    web_url: 'http://localhost/user8',
    status_tooltip_html: null,
    path: '/user8',
  },
  issue_iid: 1,
  pipeline: {
    id: 3,
    path: '/namespace6/project6/-/pipelines/3',
  },
  issue_url: 'http://localhost/namespace1/project1/issues/1',
  category: 'sast',
  feedback_type: 'issue',
  branch: 'main',
  project_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
  link_type: 'created',
};

export default [
  {
    id: 1,
    report_type: 'sast',
    name: 'Insecure variable usage',
    severity: 'critical',
    confidence: 'high',
    url: '/testgroup/testproject/-/security/vulnerabilities/1',
    scanner: {
      external_id: 'find_sec_bugs',
      name: 'Find Security Bugs',
      vendor: 'GitLab',
    },
    identifiers: [
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
    ],
    project_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
    project: {
      id: 1,
      name: 'project1',
      full_path: '/namespace1/project1',
      full_name: 'Gitab.org / security-products / binaries',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    issue_links: [],
    create_vulnerability_feedback_issue_path: 'https://example.com/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: 'https://example.com/vulnerability_feedback',
    description: 'The cipher does not provide data integrity update 1',
    solution:
      'GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.',
    location: {
      file: 'maven/src/main/java/com/gitlab/security_products/tests/App.java',
      start_line: 29,
      end_line: 29,
      class: 'com.gitlab.security_products.tests.App',
      method: 'insecureCypher',
      hostname: 'https://gitlab.com',
      path: '/user6',
    },
    links: [
      {
        name: 'Cipher does not check for integrity first?',
        url:
          'https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first',
      },
    ],
    instances: [
      {
        param: 'X-Content-Type-Options',
        method: 'GET',
        uri: 'http://bikebilly-spring-auto-devops-review-feature-br-3y2gpb.35.192.176.43.xip.io',
      },
      {
        param: 'X-Content-Type-Options',
        method: 'GET',
        uri: 'http://bikebilly-spring-auto-devops-review-feature-br-3y2gpb.35.192.176.43.xip.io/',
      },
    ],
  },
  {
    id: 2,
    report_type: 'sast',
    name: 'Insecure variable usage',
    severity: 'critical',
    confidence: 'high',
    url: '/testgroup/testproject/-/security/vulnerabilities/2',
    scanner: {
      external_id: 'find_sec_bugs',
      name: 'Find Security Bugs',
      vendor: 'GitLab',
    },
    identifiers: [
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
    ],
    project_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
    project: {
      id: 1,
      name: 'project1',
      full_path: '/namespace1/project1',
      full_name: 'Gitab.org / quality / staging',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    issue_links: [],
    create_vulnerability_feedback_issue_path: 'https://example.com/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: 'https://example.com/vulnerability_feedback',
    description: 'The cipher does not provide data integrity update 1',
    solution:
      'GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.',
    location: {
      file: 'maven/src/main/java/com/gitlab/security_products/tests/App.java',
      start_line: 29,
      end_line: 29,
      class: 'com.gitlab.security_products.tests.App',
      method: 'insecureCypher',
    },
    links: [
      {
        name: 'Cipher does not check for integrity first?',
        url:
          'https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first',
      },
    ],
  },
  {
    id: 3,
    report_type: 'sast',
    name: 'Insecure variable usage',
    severity: 'medium',
    confidence: '',
    url: '/testgroup/testproject/-/security/vulnerabilities/3',
    scanner: {
      external_id: 'find_sec_bugs',
      name: 'Find Security Bugs',
      vendor: 'GitLab',
    },
    identifiers: [
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
    ],
    project_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
    project: {
      id: 1,
      name: 'project1',
      full_path: '/namespace1/project1',
      full_name: 'Gitab.org / security-products / licence-management',
    },
    dismissal_feedback: {
      id: 1,
      project_id: 1,
      author: {
        id: 6,
        name: 'John Doe7',
        username: 'user6',
        state: 'active',
        avatar_url:
          'https://www.gravatar.com/avatar/3de3cc5a52553af613b6c457da6c219a?s=80&d=identicon',
        web_url: 'http://localhost/user6',
        status_tooltip_html: null,
        path: '/user6',
      },
      issue_iid: null,
      pipeline: {
        id: 2,
        path: '/namespace5/project5/-/pipelines/2',
      },
      category: 'sast',
      feedback_type: 'dismissal',
      branch: 'main',
      project_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
      destroy_vulnerability_feedback_dismissal_path: 'https://example.com/feedback_dismissal_path',
    },
    state_transitions: [{ to_state: 'dismissed' }],
    issue_feedback: null,
    issue_links: [],
    create_vulnerability_feedback_issue_path: 'https://example.com/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: 'https://example.com/vulnerability_feedback',
    description: 'The cipher does not provide data integrity update 1',
    solution:
      'GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.',
    location: {
      file: 'maven/src/main/java/com/gitlab/security_products/tests/App.java',
      start_line: 29,
      end_line: 29,
      class: 'com.gitlab.security_products.tests.App',
      method: 'insecureCypher',
    },
    links: [
      {
        name: 'Cipher does not check for integrity first?',
        url:
          'https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first',
      },
    ],
  },
  {
    id: 4,
    report_type: 'sast',
    name: 'Insecure variable usage',
    severity: 'high',
    confidence: 'low',
    url: '/testgroup/testproject/-/security/vulnerabilities/4',
    scanner: {
      external_id: 'find_sec_bugs',
      name: 'Find Security Bugs',
      vendor: 'GitLab',
    },
    identifiers: [
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
    ],
    project_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
    project: {
      id: 1,
      name: 'project1',
      full_path: '/namespace1/project1',
      full_name: 'Gitab.org / security-products / codequality',
    },
    dismissal_feedback: null,
    issue_feedback: issueData,
    issue_links: [issueData],
  },
  {
    id: 5,
    report_type: 'sast',
    name:
      'Remote command execution due to flaw in the include params attribute of URL and Anchor tags for org.apache.struts/struts2core',
    severity: 'low',
    confidence: '',
    url: '/testgroup/testproject/-/security/vulnerabilities/5',
    scanner: {
      external_id: 'find_sec_bugs',
      name: 'Find Security Bugs',
      vendor: 'GitLab',
    },
    identifiers: [
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
    ],
    project_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
    project: {
      id: 1,
      name: 'project1',
      full_path: '/namespace1/project1',
      full_name: 'Gitab.org / security-products / staging',
    },
    dismissal_feedback: {
      id: 1,
      project_id: 1,
      author: {
        id: 6,
        name: 'John Doe7',
        username: 'user6',
        state: 'active',
        avatar_url:
          'https://www.gravatar.com/avatar/3de3cc5a52553af613b6c457da6c219a?s=80&d=identicon',
        web_url: 'http://localhost/user6',
        status_tooltip_html: null,
        path: '/user6',
      },
      issue_iid: null,
      pipeline: {
        id: 2,
        path: '/namespace5/project5/-/pipelines/2',
      },
      category: 'sast',
      feedback_type: 'dismissal',
      branch: 'main',
      project_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
      destroy_vulnerability_feedback_dismissal_path: 'https://example.com/feedback_dismissal_path',
    },
    issue_feedback: issueData,
    issue_links: [issueData],
    create_vulnerability_feedback_issue_path: 'https://example.com/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: 'https://example.com/vulnerability_feedback',
    description: 'The cipher does not provide data integrity update 1',
    solution:
      'GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.',
    location: {
      file: 'maven/src/main/java/com/gitlab/security_products/tests/App.java',
      start_line: 29,
      end_line: 29,
      class: 'com.gitlab.security_products.tests.App',
      method: 'insecureCypher',
    },
    links: [
      {
        name: 'Cipher does not check for integrity first?',
        url:
          'https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first',
      },
    ],
  },
  {
    id: 6,
    report_type: 'sast',
    name: 'Doorkeeper Gem does not revoke token for public clients',
    severity: 'unknown',
    confidence: '',
    url: '/testgroup/testproject/-/security/vulnerabilities/6',
    scanner: {
      external_id: 'find_sec_bugs',
      name: 'Find Security Bugs',
      vendor: 'GitLab',
    },
    identifiers: [
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
    ],
    project_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
    project: {
      id: 1,
      name: 'project1',
      full_path: '/namespace1/project1',
      full_name: 'Gitab.org / security-products / binaries',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    issue_links: [],
    create_vulnerability_feedback_issue_path: 'https://example.com/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: 'https://example.com/vulnerability_feedback',
    description: 'The cipher does not provide data integrity update 1',
    solution:
      'GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.',
    location: {
      file: 'maven/src/main/java/com/gitlab/security_products/tests/App.java',
      start_line: 29,
      end_line: 29,
      class: 'com.gitlab.security_products.tests.App',
      method: 'insecureCypher',
    },
    links: [
      {
        name: 'Cipher does not check for integrity first?',
        url:
          'https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first',
      },
    ],
  },
  {
    id: 7,
    report_type: 'sast',
    name: 'Insecure variable usage',
    severity: 'high',
    confidence: 'low',
    url: '/testgroup/testproject/-/security/vulnerabilities/7',
    scanner: {
      external_id: 'find_sec_bugs',
      name: 'Find Security Bugs',
      vendor: 'GitLab',
    },
    identifiers: [
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
      {
        external_type: 'CVE',
        external_id: 'CVE-2018-1234',
        name: 'CVE-2018-1234',
        url: 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=2018-1234',
      },
    ],
    project_fingerprint: '4e5b6966dd100170b4b1ad599c7058cce91b57b4',
    project: {
      id: 1,
      name: 'project1',
      full_path: '/namespace1/project1',
      full_name: 'Gitab.org / security-products / codequality',
    },
    dismissal_feedback: null,
    issue_feedback: issueData,
    issue_links: [issueData],
    vulnerability_feedback_issue_path: 'https://example.com/vulnerability_feedback',
    vulnerability_feedback_dismissal_path: 'https://example.com/vulnerability_feedback',
    description: 'The cipher does not provide data integrity update 1',
    solution:
      'GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.',
    location: {
      file: 'maven/src/main/java/com/gitlab/security_products/tests/App.java',
      start_line: 29,
      end_line: 29,
      class: 'com.gitlab.security_products.tests.App',
      method: 'insecureCypher',
    },
    links: [
      {
        name: 'Cipher does not check for integrity first?',
        url:
          'https://crypto.stackexchange.com/questions/31428/pbewithmd5anddes-cipher-does-not-check-for-integrity-first',
      },
    ],
  },
  {
    id: 8,
    report_type: 'container_scanning',
    name: 'CVE-2018-1000001 in glibc',
    severity: 'high',
    confidence: 'unknown',
    url: '/testgroup/testproject/-/security/vulnerabilities/8',
    scanner: {
      external_id: 'trivy',
      name: 'Trivy',
      vendor: 'GitLab',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-1000001',
        name: 'CVE-2018-1000001',
        url: 'https://security-tracker.debian.org/tracker/CVE-2018-1000001',
      },
    ],
    project_fingerprint: 'af08ab5aa899af9e74318ebc23684c9aa728ab7c',
    create_vulnerability_feedback_issue_path: '/gitlab-org/sec-reports/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/sec-reports/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: '/gitlab-org/sec-reports/vulnerability_feedback',
    project: {
      id: 19,
      name: 'sec-reports',
      full_path: '/gitlab-org/sec-reports',
      full_name: 'Gitlab Org / sec-reports',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    issue_links: [],
    merge_request_feedback: null,
    description:
      'In glibc 2.26 and earlier there is confusion in the usage of getcwd() by realpath() which can be used to write before the destination buffer leading to a buffer underflow and potential code execution.',
    links: [
      {
        url: 'https://security-tracker.debian.org/tracker/CVE-2018-1000001',
      },
    ],
    location: {
      image:
        'registry.gitlab.com/groulot/container-scanning-test/main:5f21de6956aee99ddb68ae49498662d9872f50ff',
      operating_system: 'debian:9',
      dependency: {
        package: {
          name: 'glibc',
        },
        version: '2.24-11+deb9u3',
      },
    },
    remediations: null,
    solution: null,
    state: 'opened',
    blob_path: '',
  },
  {
    id: 9,
    create_jira_issue_url: 'http://jira-project.atlassian.com/report',
    report_type: 'container_scanning',
    name: 'CVE-2018-1000001 in glibc',
    severity: 'high',
    confidence: 'unknown',
    url: '/testgroup/testproject/-/security/vulnerabilities/9',
    scanner: {
      external_id: 'trivy',
      name: 'Trivy',
      vendor: 'GitLab',
    },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2018-1000001',
        name: 'CVE-2018-1000001',
        url: 'https://security-tracker.debian.org/tracker/CVE-2018-1000001',
      },
    ],
    project_fingerprint: 'af08ab5aa899af9e74318ebc23684c9aa728ab7c',
    create_vulnerability_feedback_issue_path: '/gitlab-org/sec-reports/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/sec-reports/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: '/gitlab-org/sec-reports/vulnerability_feedback',
    project: {
      id: 19,
      name: 'sec-reports',
      full_path: '/gitlab-org/sec-reports',
      full_name: 'Gitlab Org / sec-reports',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    issue_links: [],
    merge_request_feedback: null,
    description:
      'In glibc 2.26 and earlier there is confusion in the usage of getcwd() by realpath() which can be used to write before the destination buffer leading to a buffer underflow and potential code execution.',
    links: [
      {
        url: 'https://security-tracker.debian.org/tracker/CVE-2018-1000001',
      },
    ],
    location: {
      image:
        'registry.gitlab.com/groulot/container-scanning-test/main:5f21de6956aee99ddb68ae49498662d9872f50ff',
      operating_system: 'debian:9',
      dependency: {
        package: {
          name: 'glibc',
        },
        version: '2.24-11+deb9u3',
      },
    },
    remediations: null,
    solution: null,
    state: 'opened',
    blob_path: '',
  },
];
