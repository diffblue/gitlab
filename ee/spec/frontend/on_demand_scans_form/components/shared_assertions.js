/* eslint-disable jest/no-export */
import { cloneDeep, set } from 'lodash';
import siteProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.basic.json';
import scannerProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql.basic.json';
import waitForPromises from 'helpers/wait_for_promises';
import ScannerProfileSelector from 'ee/on_demand_scans_form/components/profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from 'ee/on_demand_scans_form/components/profile_selector/site_profile_selector.vue';

const [firstSiteProfile] = siteProfilesFixtures.data.project.siteProfiles.nodes;
const [firstScannerProfile] = scannerProfilesFixtures.data.project.scannerProfiles.nodes;
const siteProfilesReponseWithSingleProfile = set(
  cloneDeep(siteProfilesFixtures),
  'data.project.siteProfiles.nodes',
  [firstSiteProfile],
);
const scannerProfilesReponseWithSingleProfile = set(
  cloneDeep(scannerProfilesFixtures),
  'data.project.scannerProfiles.nodes',
  [firstScannerProfile],
);

export const itSelectsOnlyAvailableProfile = (componentFactory) => {
  let wrapper;

  describe.each`
    profileType  | query                    | selector                  | response                                   | expectedId
    ${'site'}    | ${'dastSiteProfiles'}    | ${SiteProfileSelector}    | ${siteProfilesReponseWithSingleProfile}    | ${firstSiteProfile.id}
    ${'scanner'} | ${'dastScannerProfiles'} | ${ScannerProfileSelector} | ${scannerProfilesReponseWithSingleProfile} | ${firstScannerProfile.id}
  `('when there is a single $profileType profile', ({ query, selector, response, expectedId }) => {
    beforeEach(async () => {
      wrapper = componentFactory(
        {},
        {
          [query]: jest.fn().mockResolvedValue(response),
        },
      );

      await waitForPromises();
    });

    it('automatically selects the only available profile', () => {
      expect(wrapper.findComponent(selector).attributes('value')).toBe(expectedId);
    });
  });
};
