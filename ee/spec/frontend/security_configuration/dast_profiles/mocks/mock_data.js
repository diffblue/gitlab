import siteProfilesFixture from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.basic.json';

export const siteProfiles = siteProfilesFixture.data.project.siteProfiles.edges.map(
  ({ node }) => node,
);

export const nonValidatedSiteProfile = siteProfiles.find(
  ({ validationStatus }) => validationStatus === 'NONE',
);
export const validatedSiteProfile = siteProfiles.find(
  ({ validationStatus }) => validationStatus === 'PASSED_VALIDATION',
);

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
