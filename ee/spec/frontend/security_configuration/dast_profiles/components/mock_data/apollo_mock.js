import { merge } from 'lodash';

export const siteProfilesResponse = (overrides = {}) => {
  return {
    data: {
      project: {
        id: '1',
        __typename: 'Project',
        siteProfiles: merge(
          {},
          {
            nodes: [
              {
                id: '1',
                profileName: 'Test',
                normalizedTargetUrl: 'https://gitlab.com:443',
                targetUrl: 'https://gitlab.com',
                targetType: 'WEBSITE',
                editPath:
                  '/security/security-reports/-/security/configuration/profile_library/dast_site_profiles/3/edit',
                validationStatus: 'NONE',
                validationStartedAt: null,
                referencedInSecurityPolicies: [],
                auth: {
                  enabled: false,
                  url: null,
                  usernameField: 'username',
                  passwordField: 'password',
                  username: null,
                  submitField: '',
                  __typename: 'DastSiteProfileAuth',
                },
                excludedUrls: [],
                requestHeaders: null,
                scanMethod: 'WEBSITE',
                scanFilePath: null,
                __typename: 'DastSiteProfile',
              },
            ],
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: 0,
              endCursor: 0,
            },
          },
          overrides,
        ),
      },
    },
  };
};

export const scannerProfilesResponse = (overrides = {}) => {
  return {
    data: {
      project: {
        id: '1',
        __typename: 'Project',
        scannerProfiles: merge(
          {},
          {
            nodes: [
              {
                id: '1',
                profileName: 'Test',
                spiderTimeout: 1,
                targetTimeout: 60,
                scanType: 'PASSIVE',
                useAjaxSpider: false,
                showDebugMessages: false,
                editPath:
                  '/security/security-reports/-/security/configuration/profile_library/dast_scanner_profiles/2/edit',
                referencedInSecurityPolicies: [],
                __typename: 'DastScannerProfile',
              },
            ],
            pageInfo: {
              __typename: 'PageInfo',
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: 0,
              endCursor: 0,
            },
          },
          overrides,
        ),
      },
    },
  };
};

export const siteProfileDeleteResponse = (errors = []) => {
  return { data: { siteProfilesDelete: { errors } } };
};

export const scannerProfileDeleteResponse = (errors = []) => {
  return { data: { scannerProfilesDelete: { errors } } };
};
