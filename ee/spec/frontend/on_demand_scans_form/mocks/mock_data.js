export const scannerProfiles = [
  {
    id: 'gid://gitlab/DastScannerProfile/1',
    profileName: 'Scanner profile #1',
    spiderTimeout: 5,
    targetTimeout: 10,
    scanType: 'PASSIVE',
    useAjaxSpider: false,
    showDebugMessages: false,
    editPath: '/scanner_profile/edit/1',
    referencedInSecurityPolicies: [],
  },
  {
    id: 'gid://gitlab/DastScannerProfile/2',
    profileName: 'Scanner profile #2',
    spiderTimeout: 20,
    targetTimeout: 150,
    scanType: 'ACTIVE',
    useAjaxSpider: true,
    showDebugMessages: true,
    editPath: '/scanner_profile/edit/2',
    referencedInSecurityPolicies: [],
  },
];

export const policyScannerProfile = {
  id: 'gid://gitlab/DastScannerProfile/3',
  profileName: 'Scanner profile #3',
  spiderTimeout: 20,
  targetTimeout: 150,
  scanType: 'ACTIVE',
  useAjaxSpider: true,
  showDebugMessages: true,
  editPath: '/scanner_profile/edit/3',
  referencedInSecurityPolicies: ['some_policy'],
};

export const siteProfiles = [
  {
    id: 'gid://gitlab/DastSiteProfile/1',
    profileName: 'Site profile #1',
    targetUrl: 'https://foo.com',
    targetType: 'WEBSITE',
    normalizedTargetUrl: 'https://foo.com:443',
    editPath: '/site_profiles/edit/1',
    validationStatus: 'PENDING_VALIDATION',
    auth: {
      enabled: true,
      url: 'https://foo.com/login',
      usernameField: 'username',
      passwordField: 'password',
      username: 'admin',
      password: 'password',
    },
    excludedUrls: ['https://foo.com/logout', 'https://foo.com/send_mail'],
    requestHeaders: 'log-identifier: dast-active-scan',
    referencedInSecurityPolicies: [],
  },
  {
    id: 'gid://gitlab/DastSiteProfile/2',
    profileName: 'Site profile #2',
    targetUrl: 'https://bar.com',
    targetType: 'API',
    normalizedTargetUrl: 'https://bar.com:443',
    editPath: '/site_profiles/edit/2',
    validationStatus: 'PASSED_VALIDATION',
    auth: {
      enabled: false,
      url: 'https://foo.com/login',
      usernameField: 'username',
      passwordField: 'password',
      username: 'admin',
    },
    excludedUrls: ['https://bar.com/logout'],
    requestHeaders: 'auth: gitlab-dast',
    referencedInSecurityPolicies: [],
  },
];

export const policySiteProfile = {
  id: 'gid://gitlab/DastSiteProfile/6',
  profileName: 'Profile 6',
  targetUrl: 'http://example-6.com',
  normalizedTargetUrl: 'http://example-6.com',
  editPath: '/6/edit',
  validationStatus: 'NONE',
  auth: {
    enabled: false,
  },
  excludedUrls: ['https://bar.com/logout'],
  referencedInSecurityPolicies: ['some_policy'],
  targetType: 'WEBSITE',
};
