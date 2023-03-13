import Vue from 'vue';
import VueApollo from 'vue-apollo';
import siteProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.basic.json';
import scannerProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql.basic.json';
import * as responses from 'ee_jest/security_configuration/dast_profiles/mocks/apollo_mock';
import dastScannerProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql';
import dastSiteProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql';
import dastSiteValidationsQuery from 'ee/security_configuration/dast_site_validation/graphql/dast_site_validations.query.graphql';
import resolvers from 'ee/vue_shared/security_configuration/graphql/resolvers/resolvers';
import { typePolicies } from 'ee/vue_shared/security_configuration/graphql/provider';
import createApolloProvider from 'helpers/mock_apollo_helper';

const defaultHandlers = {
  dastScannerProfiles: jest.fn().mockResolvedValue(scannerProfilesFixtures),
  dastSiteProfiles: jest.fn().mockResolvedValue(siteProfilesFixtures),
  validations: jest.fn().mockResolvedValue(responses.dastSiteValidations()),
};
export const createMockApolloProvider = (additionalHandlers = []) => {
  Vue.use(VueApollo);

  return createApolloProvider(
    [
      [dastScannerProfilesQuery, defaultHandlers.dastScannerProfiles],
      [dastSiteProfilesQuery, defaultHandlers.dastSiteProfiles],
      [dastSiteValidationsQuery, defaultHandlers.validations],
      ...additionalHandlers,
    ],
    resolvers,
    { typePolicies },
  );
};
