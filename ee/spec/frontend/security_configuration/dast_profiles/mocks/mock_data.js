import siteProfilesFixture from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.basic.json';
import scannerProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql.basic.json';
import profilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_profiles.query.graphql.json';
import policySiteProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.from_policies.json';
import policyScannerProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql.from_policies.json';

export const siteProfiles = siteProfilesFixture.data.project.siteProfiles.edges.map(
  ({ node }) => node,
);

export const nonValidatedSiteProfile = siteProfiles.find(
  ({ validationStatus }) => validationStatus === 'NONE',
);
export const validatedSiteProfile = siteProfiles.find(
  ({ validationStatus }) => validationStatus === 'PASSED_VALIDATION',
);

export const policySiteProfiles = policySiteProfilesFixtures.data.project.siteProfiles.edges.map(
  ({ node }) => node,
);

export const policyScannerProfiles = policyScannerProfilesFixtures.data.project.scannerProfiles.edges.map(
  ({ node }) => node,
);

export const scannerProfiles = scannerProfilesFixtures.data.project.scannerProfiles.edges.map(
  ({ node }) => node,
);

export const savedScans = profilesFixtures.data.project.dastProfiles.edges.map(({ node }) => node);

export const failedSiteValidations = [
  {
    id: '1',
    normalizedTargetUrl: 'http://example.com:80',
  },
  {
    id: '2',
    normalizedTargetUrl: 'https://example.com:443',
  },
];
