import siteProfilesFixture from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.basic.json';
import scannerProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql.basic.json';
import policySiteProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.from_policies.json';
import policyScannerProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql.from_policies.json';
import dastFailedSiteValidationsFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_failed_site_validations.query.graphql.json';

export const siteProfiles = siteProfilesFixture.data.project.siteProfiles.nodes;

export const nonValidatedSiteProfile = siteProfiles.find(
  ({ validationStatus }) => validationStatus === 'NONE',
);
export const validatedSiteProfile = siteProfiles.find(
  ({ validationStatus }) => validationStatus === 'PASSED_VALIDATION',
);

export const policySiteProfiles = policySiteProfilesFixtures.data.project.siteProfiles.nodes;

export const policyScannerProfiles =
  policyScannerProfilesFixtures.data.project.scannerProfiles.nodes;

export const scannerProfiles = scannerProfilesFixtures.data.project.scannerProfiles.nodes;

export const activeScannerProfile = scannerProfiles.find(({ scanType }) => scanType === 'ACTIVE');
export const passiveScannerProfile = scannerProfiles.find(({ scanType }) => scanType === 'PASSIVE');

export const failedSiteValidations =
  dastFailedSiteValidationsFixtures.data.project.validations.nodes;

export const mockSharedData = {
  showDiscardChangesModal: false,
  formTouched: false,
  history: [],
  cashedPayload: {
    __typename: 'CachedPayload',
    profileType: '',
    mode: '',
  },
  resetAndClose: false,
  __typename: 'SharedData',
};
