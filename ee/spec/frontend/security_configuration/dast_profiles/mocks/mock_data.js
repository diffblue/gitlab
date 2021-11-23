export const siteProfiles = [
  {
    id: 'gid://gitlab/DastSiteProfile/1',
    profileName: 'Profile 1',
    targetUrl: 'http://example-1.com',
    normalizedTargetUrl: 'http://example-1.com',
    editPath: '/1/edit',
    validationStatus: 'PENDING_VALIDATION',
    referencedInSecurityPolicies: [],
  },
  {
    id: 'gid://gitlab/DastSiteProfile/2',
    profileName: 'Profile 2',
    targetUrl: 'http://example-2.com',
    normalizedTargetUrl: 'http://example-2.com',
    editPath: '/2/edit',
    validationStatus: 'INPROGRESS_VALIDATION',
    referencedInSecurityPolicies: [],
  },
  {
    id: 'gid://gitlab/DastSiteProfile/3',
    profileName: 'Profile 3',
    targetUrl: 'http://example-2.com',
    normalizedTargetUrl: 'http://example-2.com',
    editPath: '/3/edit',
    validationStatus: 'PASSED_VALIDATION',
    referencedInSecurityPolicies: [],
  },
  {
    id: 'gid://gitlab/DastSiteProfile/4',
    profileName: 'Profile 4',
    targetUrl: 'http://example-3.com',
    normalizedTargetUrl: 'http://example-3.com',
    editPath: '/3/edit',
    validationStatus: 'FAILED_VALIDATION',
    referencedInSecurityPolicies: [],
  },
  {
    id: 'gid://gitlab/DastSiteProfile/5',
    profileName: 'Profile 5',
    targetUrl: 'http://example-5.com',
    normalizedTargetUrl: 'http://example-5.com',
    editPath: '/5/edit',
    validationStatus: 'NONE',
    referencedInSecurityPolicies: [],
  },
];

export const policySiteProfile = [
  {
    id: 'gid://gitlab/DastSiteProfile/6',
    profileName: 'Profile 6',
    targetUrl: 'http://example-6.com',
    normalizedTargetUrl: 'http://example-6.com',
    editPath: '/6/edit',
    validationStatus: 'NONE',
    referencedInSecurityPolicies: ['some_policy'],
  },
];

export const scannerProfiles = [
  {
    id: 'gid://gitlab/DastScannerProfile/1',
    profileName: 'Scanner profile #1',
    spiderTimeout: 5,
    targetTimeout: 10,
    scanType: 'PASSIVE',
    useAjaxSpider: false,
    showDebugMessages: false,
  },
  {
    id: 'gid://gitlab/DastScannerProfile/2',
    profileName: 'Scanner profile #2',
    spiderTimeout: 20,
    targetTimeout: 150,
    scanType: 'ACTIVE',
    useAjaxSpider: true,
    showDebugMessages: true,
  },
];

export const savedScans = [
  {
    id: 'gid://gitlab/DastProfile/1',
    name: 'Scan 1',
    dastSiteProfile: siteProfiles[0],
    dastScannerProfile: scannerProfiles[0],
    editPath: '/1/edit',
    branch: {
      name: 'main',
      exists: true,
    },
  },
  {
    id: 'gid://gitlab/DastProfile/2',
    name: 'Scan 2',
    dastSiteProfile: siteProfiles[1],
    dastScannerProfile: scannerProfiles[1],
    editPath: '/2/edit',
    branch: {
      name: 'feature-branch',
      exists: false,
    },
  },
];

export const failedSiteValidations = [
  {
    normalizedTargetUrl: 'http://example.com:80',
  },
  {
    normalizedTargetUrl: 'https://example.com:443',
  },
];
