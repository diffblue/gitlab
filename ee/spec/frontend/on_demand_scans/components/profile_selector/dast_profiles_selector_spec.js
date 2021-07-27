import { GlSprintf, GlSkeletonLoader } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import DastProfilesSelector from 'ee/on_demand_scans/components/profile_selector/dast_profiles_selector.vue';
import ScannerProfileSelector from 'ee/on_demand_scans/components/profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from 'ee/on_demand_scans/components/profile_selector/site_profile_selector.vue';
import dastScannerProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql';
import dastSiteProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql';
import createApolloProvider from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as responses from '../../mocks/apollo_mocks';
import { scannerProfiles, siteProfiles } from '../../mocks/mock_data';

const URL_HOST = 'https://localhost/';

const fullPath = '/project/path';

const [passiveScannerProfile, activeScannerProfile] = scannerProfiles;
const [nonValidatedSiteProfile, validatedSiteProfile] = siteProfiles;

beforeEach(() => {
  setWindowLocation(URL_HOST);
});

describe('EE - DAST Profiles Selector', () => {
  let wrapper;
  let localVue;
  let requestHandlers;

  const findScannerProfilesSelector = () => wrapper.findComponent(ScannerProfileSelector);
  const findSiteProfilesSelector = () => wrapper.findComponent(SiteProfileSelector);
  const findProfilesConflictAlert = () => wrapper.findByTestId('dast-profiles-conflict-alert');

  const createMockApolloProvider = (handlers) => {
    localVue.use(VueApollo);
    requestHandlers = {
      dastScannerProfiles: jest.fn().mockResolvedValue(responses.dastScannerProfiles()),
      dastSiteProfiles: jest.fn().mockResolvedValue(responses.dastSiteProfiles()),
      ...handlers,
    };
    return createApolloProvider([
      [dastScannerProfilesQuery, requestHandlers.dastScannerProfiles],
      [dastSiteProfilesQuery, requestHandlers.dastSiteProfiles],
    ]);
  };

  const createComponentFactory = (mountFn = shallowMountExtended) => (
    options = {},
    withHandlers,
  ) => {
    localVue = createLocalVue();
    let defaultMocks = {
      $apollo: {
        queries: {
          siteProfiles: {},
          scannerProfiles: {},
        },
      },
    };

    let apolloProvider;
    if (withHandlers) {
      apolloProvider = createMockApolloProvider(withHandlers);
      defaultMocks = {};
    }

    wrapper = mountFn(
      DastProfilesSelector,
      merge(
        {},
        {
          mocks: defaultMocks,
          provide: {
            fullPath,
          },
          stubs: {
            GlSprintf,
          },
        },
        { ...options, localVue, apolloProvider },
        {
          data() {
            return {
              scannerProfiles,
              siteProfiles,
              ...options.data,
            };
          },
        },
      ),
    );
  };

  const createComponent = createComponentFactory();

  afterEach(() => {
    wrapper.destroy();
  });

  describe('loading state', () => {
    it.each`
      scannerProfilesLoading | siteProfilesLoading | isLoading
      ${true}                | ${true}             | ${true}
      ${false}               | ${true}             | ${true}
      ${true}                | ${false}            | ${true}
      ${false}               | ${false}            | ${false}
    `(
      'sets loading state to $isLoading if scanner profiles loading is $scannerProfilesLoading and site profiles loading is $siteProfilesLoading',
      ({ scannerProfilesLoading, siteProfilesLoading, isLoading }) => {
        createComponent({
          mocks: {
            $apollo: {
              queries: {
                scannerProfiles: { loading: scannerProfilesLoading },
                siteProfiles: { loading: siteProfilesLoading },
              },
            },
          },
        });

        expect(wrapper.find(GlSkeletonLoader).exists()).toBe(isLoading);
      },
    );
  });

  describe.each`
    description                                  | selectedScannerProfile   | selectedSiteProfile        | hasConflict
    ${'a passive scan and a non-validated site'} | ${passiveScannerProfile} | ${nonValidatedSiteProfile} | ${false}
    ${'a passive scan and a validated site'}     | ${passiveScannerProfile} | ${validatedSiteProfile}    | ${false}
    ${'an active scan and a non-validated site'} | ${activeScannerProfile}  | ${nonValidatedSiteProfile} | ${true}
    ${'an active scan and a validated site'}     | ${activeScannerProfile}  | ${validatedSiteProfile}    | ${false}
  `(
    'profiles conflict prevention',
    ({ description, selectedScannerProfile, selectedSiteProfile, hasConflict }) => {
      const setFormData = () => {
        findScannerProfilesSelector().vm.$emit('input', selectedScannerProfile.id);
        findSiteProfilesSelector().vm.$emit('input', selectedSiteProfile.id);
        return wrapper.vm.$nextTick();
      };

      it(
        hasConflict
          ? `warns about conflicting profiles when user selects ${description}`
          : `does not report any conflict when user selects ${description}`,
        async () => {
          createComponent();
          await setFormData();

          expect(findProfilesConflictAlert().exists()).toBe(hasConflict);
        },
      );
    },
  );

  describe.each`
    profileType  | query                    | selector                  | profiles
    ${'scanner'} | ${'dastScannerProfiles'} | ${ScannerProfileSelector} | ${scannerProfiles}
    ${'site'}    | ${'dastSiteProfiles'}    | ${SiteProfileSelector}    | ${siteProfiles}
  `('when there is a single $profileType profile', ({ query, selector, profiles }) => {
    const [profile] = profiles;

    beforeEach(async () => {
      createComponent(
        {},
        {
          [query]: jest.fn().mockResolvedValue(responses[query]([profile])),
        },
      );

      await waitForPromises();
    });

    it('automatically selects the only available profile', () => {
      expect(wrapper.find(selector).attributes('value')).toBe(profile.id);
    });
  });

  describe('populate profiles from query params', () => {
    const [siteProfile] = siteProfiles;
    const [scannerProfile] = scannerProfiles;

    it('scanner profile', () => {
      setWindowLocation(`?scanner_profile_id=1`);
      createComponent();

      expect(findScannerProfilesSelector().attributes('value')).toBe(scannerProfile.id);
    });

    it('site profile', () => {
      setWindowLocation(`?site_profile_id=1`);
      createComponent();

      expect(findSiteProfilesSelector().attributes('value')).toBe(siteProfile.id);
    });

    it('both scanner & site profile', () => {
      setWindowLocation(`?site_profile_id=1&scanner_profile_id=1`);
      createComponent();

      expect(wrapper.find(SiteProfileSelector).attributes('value')).toBe(siteProfile.id);
      expect(wrapper.find(ScannerProfileSelector).attributes('value')).toBe(scannerProfile.id);
    });
  });
});
