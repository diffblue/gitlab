import { merge } from 'lodash';
import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import { createLocalVue, mount, shallowMount } from '@vue/test-utils';
import siteProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.basic.json';
import scannerProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql.basic.json';
import { s__ } from '~/locale';
import DastProfilesConfigurator from 'ee/security_configuration/dast_profiles/dast_profiles_configurator/dast_profiles_configurator.vue';
import ScannerProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_selector.vue';
import ScannerProfileSummary from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_summary.vue';
import SiteProfileSummary from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_summary.vue';
import DastProfilesSidebar from 'ee/security_configuration/dast_profiles/dast_profiles_sidebar/dast_profiles_sidebar.vue';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import SectionLoader from '~/vue_shared/security_configuration/components/section_loader.vue';
import dastScannerProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql';
import dastSiteProfilesQuery from 'ee/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import createApolloProvider from 'helpers/mock_apollo_helper';
import {
  siteProfiles,
  scannerProfiles,
  validatedSiteProfile,
} from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

const [passiveScannerProfile] = scannerProfiles;
useLocalStorageSpy();
const LOCAL_STORAGE_KEY = '/on-demand-scans-new-form';

describe('DastProfilesConfigurator', () => {
  let localVue;
  let wrapper;
  let requestHandlers;

  const createMockApolloProvider = (handlers) => {
    localVue.use(VueApollo);

    requestHandlers = {
      dastScannerProfiles: jest.fn().mockResolvedValue(scannerProfilesFixtures),
      dastSiteProfiles: jest.fn().mockResolvedValue(siteProfilesFixtures),
      ...handlers,
    };

    return createApolloProvider([
      [dastScannerProfilesQuery, requestHandlers.dastScannerProfiles],
      [dastSiteProfilesQuery, requestHandlers.dastSiteProfiles],
    ]);
  };

  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const findSectionLayout = () => wrapper.find(SectionLayout);
  const findSectionLoader = () => wrapper.find(SectionLoader);
  const findScannerProfilesSelector = () => wrapper.find(ScannerProfileSelector);
  const findSiteProfilesSelector = () => wrapper.find(SiteProfileSelector);
  const findScannerProfileSummary = () => wrapper.find(ScannerProfileSummary);
  const findAllScannerProfileSummary = () => wrapper.findAll(ScannerProfileSummary);
  const findSiteProfileSummary = () => wrapper.find(SiteProfileSummary);
  const findAllSiteProfileSummary = () => wrapper.findAll(SiteProfileSummary);
  const findDastProfileSidebar = () => wrapper.find(DastProfilesSidebar);
  const findSelectProfileButton = () => findByTestId('select-profile-action-btn');
  const findSelectProfileSummaryButton = () => findByTestId('profile-select-btn');

  const createComponentFactory = (mountFn = shallowMount) => (
    options = {},
    withHandlers,
    glFeatures = {},
  ) => {
    localVue = createLocalVue();
    let defaultMocks = {
      $apollo: {
        mutate: jest.fn(),
        queries: {
          scannerProfiles: jest.fn(),
          siteProfiles: jest.fn(),
        },
      },
    };
    let apolloProvider;
    if (withHandlers) {
      apolloProvider = createMockApolloProvider(withHandlers);
      defaultMocks = {};
    }
    wrapper = mountFn(
      DastProfilesConfigurator,
      merge(
        {},
        {
          propsData: {
            ...options.props,
          },
          mocks: defaultMocks,
          provide: {
            ...glFeatures,
          },
          stubs: {
            SectionLayout,
            ScannerProfileSelector,
            SiteProfileSelector,
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
    return wrapper;
  };
  const createComponent = createComponentFactory(mount);
  const createShallowComponent = createComponentFactory();

  const selectScannerProfile = async () => {
    findSelectProfileButton().vm.$emit('click');
    await nextTick();
    findSelectProfileSummaryButton().vm.$emit('click');
    await nextTick();
  };

  const hasSelectedProfilesAttributes = () => {
    expect(findScannerProfileSummary().exists()).toBe(true);
    expect(findSiteProfileSummary().exists()).toBe(true);
    expect(findScannerProfilesSelector().find('h4').text()).toContain('Scanner Profile');
    expect(findSiteProfilesSelector().find('h4').text()).toContain('Site Profile');
    expect(wrapper.emitted('profiles-selected')).toBeTruthy();
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    localStorage.clear();
  });

  describe('when default state', () => {
    it('renders properly', () => {
      const sectionHeader = s__('OnDemandScans|DAST configuration');
      createComponent({ configurationHeader: sectionHeader });

      expect(findSectionLayout().find('h2').text()).toContain(sectionHeader);
      expect(findScannerProfilesSelector().exists()).toBe(true);
      expect(findSiteProfilesSelector().exists()).toBe(true);
    });

    it('renders a link to the docs', () => {
      createComponent();
      const link = findSectionLayout().find('a');

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(
        '/help/user/application_security/dast/index#on-demand-scans',
      );
    });

    it.each`
      scannerProfilesLoading | siteProfilesLoading | isLoading
      ${true}                | ${true}             | ${true}
      ${false}               | ${true}             | ${true}
      ${true}                | ${false}            | ${true}
      ${false}               | ${false}            | ${false}
    `(
      'sets loading state to $isLoading if scanner profiles loading is $scannerProfilesLoading and site profiles loading is $siteProfilesLoading',
      ({ scannerProfilesLoading, siteProfilesLoading, isLoading }) => {
        createShallowComponent({
          mocks: {
            $apollo: {
              queries: {
                scannerProfiles: { loading: scannerProfilesLoading },
                siteProfiles: { loading: siteProfilesLoading },
              },
            },
          },
        });

        expect(findSectionLoader().exists()).toBe(isLoading);
      },
    );
  });

  describe('local storage', () => {
    const dastScan = {
      dastScannerProfile: { id: passiveScannerProfile.id },
      dastSiteProfile: { id: validatedSiteProfile.id },
    };

    it('get updated when scanner profile is selected', async () => {
      createComponent();

      await selectScannerProfile();

      expect(localStorage.setItem.mock.calls).toEqual([
        [
          LOCAL_STORAGE_KEY,
          JSON.stringify({
            selectedScannerProfileId: passiveScannerProfile.id,
            selectedSiteProfileId: null,
          }),
        ],
      ]);
    });

    it('reload the selected scanner data when available', async () => {
      localStorage.setItem(
        LOCAL_STORAGE_KEY,
        JSON.stringify({
          selectedScannerProfileId: dastScan.dastScannerProfile.id,
          selectedSiteProfileId: dastScan.dastSiteProfile.id,
        }),
      );

      createComponent();
      await nextTick();

      hasSelectedProfilesAttributes();
    });
  });

  describe('profile drawer', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should open drawer with scanner profiles', async () => {
      findScannerProfilesSelector().vm.$emit('open-drawer');

      await nextTick();

      expect(findDastProfileSidebar().exists()).toBe(true);
      expect(findAllScannerProfileSummary()).toHaveLength(scannerProfiles.length);
    });

    it('should open drawer with site profiles', async () => {
      findSiteProfilesSelector().vm.$emit('open-drawer');

      await nextTick();

      expect(findDastProfileSidebar().exists()).toBe(true);
      expect(findAllSiteProfileSummary()).toHaveLength(siteProfiles.length);
    });
  });
});
