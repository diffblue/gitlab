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
