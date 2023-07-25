import { GlSprintf, GlTruncate } from '@gitlab/ui';
import siteProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_site_profiles.query.graphql.basic.json';
import scannerProfilesFixtures from 'test_fixtures/graphql/security_configuration/dast_profiles/graphql/dast_scanner_profiles.query.graphql.basic.json';
import { createMockApolloProvider } from 'ee_jest/security_configuration/dast_profiles/graphql/create_mock_apollo_provider';
import waitForPromises from 'helpers/wait_for_promises';
import DastProfilesDrawer from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer.vue';
import DastProfilesDrawerHeader from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer_header.vue';
import ProjectDastProfileSelector from 'ee/security_orchestration/components/policy_editor/scan_execution_policy/scan_filters/project_dast_profile_selector.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { SCANNER_TYPE, SITE_TYPE } from 'ee/on_demand_scans/constants';
import GenericBaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/generic_base_layout_component.vue';

describe('ProjectDastProfileSelector', () => {
  let wrapper;
  const createComponent = (mountFn) => ({ props = {}, handlers = [] } = {}) => {
    wrapper = mountFn(ProjectDastProfileSelector, {
      propsData: {
        ...props,
      },
      apolloProvider: createMockApolloProvider(handlers),
      provide: {
        namespacePath: 'path/to/project',
      },
      stubs: {
        GenericBaseLayoutComponent,
        GlSprintf,
      },
    });
  };

  const createFullComponent = createComponent(mountExtended);
  const createShallowComponent = createComponent(shallowMountExtended);

  const findDrawerComponent = () => wrapper.findComponent(DastProfilesDrawer);
  const findDrawerHeaderComponent = () => wrapper.findComponent(DastProfilesDrawerHeader);
  const findScannerProfileTrigger = () => wrapper.findByTestId('scanner-profile-trigger');
  const findSiteProfileTrigger = () => wrapper.findByTestId('site-profile-trigger');
  const findTriggerText = (trigger) => trigger.findComponent(GlTruncate);

  describe('loading', () => {
    it('renders scanner and site profiles triggers', () => {
      createShallowComponent();

      const scannerTrigger = findScannerProfileTrigger();
      const siteTrigger = findSiteProfileTrigger();

      expect(scannerTrigger.exists()).toBe(true);
      expect(siteTrigger.exists()).toBe(true);
      expect(scannerTrigger.props('loading')).toBe(true);
      expect(siteTrigger.props('loading')).toBe(true);
    });
  });

  describe('default', () => {
    it('renders scanner and site profiles triggers', async () => {
      createShallowComponent();
      await waitForPromises();

      const scannerTrigger = findScannerProfileTrigger();
      const siteTrigger = findSiteProfileTrigger();

      expect(scannerTrigger.exists()).toBe(true);
      expect(siteTrigger.exists()).toBe(true);

      expect(findTriggerText(scannerTrigger).props('text')).toBe('Select scanner profile');
      expect(findTriggerText(siteTrigger).props('text')).toBe('Select site profile');

      expect(scannerTrigger.props('loading')).toBe(false);
      expect(siteTrigger.props('loading')).toBe(false);
    });

    it.each`
      findTrigger                  | profileType  | drawerHeader
      ${findScannerProfileTrigger} | ${'scanner'} | ${'Scanner profile library'}
      ${findSiteProfileTrigger}    | ${'site'}    | ${'Site profile library'}
    `(
      'opens a drawer with correct profile type',
      async ({ findTrigger, profileType, drawerHeader }) => {
        createFullComponent();
        expect(findDrawerComponent().props('open')).toBe(false);

        findTrigger().vm.$emit('click');
        await waitForPromises();

        expect(findDrawerHeaderComponent().props('profileType')).toBe(profileType);
        expect(findDrawerHeaderComponent().text()).toContain(drawerHeader);
        expect(findDrawerComponent().props('open')).toBe(true);
      },
    );

    it.each`
      findTrigger                  | profileType     | selectedProfile                        | selectedProfileName
      ${findScannerProfileTrigger} | ${SCANNER_TYPE} | ${'gid://gitlab/DastScannerProfile/2'} | ${'Passive scanner'}
      ${findSiteProfileTrigger}    | ${SITE_TYPE}    | ${'gid://gitlab/DastSiteProfile/1'}    | ${'Non-validated'}
    `(
      'selects profile',
      async ({ findTrigger, profileType, selectedProfile, selectedProfileName }) => {
        createShallowComponent();

        findDrawerComponent().vm.$emit('select-profile', {
          profile: { id: selectedProfile },
          profileType,
        });

        await waitForPromises();
        expect(findTriggerText(findTrigger()).props('text')).toBe(selectedProfileName);
        expect(wrapper.emitted('profiles-selected')).toHaveLength(2);
      },
    );
  });

  describe('existing profiles', () => {
    it('selects existing scanners', async () => {
      createShallowComponent({
        props: {
          savedScannerProfileName: 'Passive scanner',
          savedSiteProfileName: 'Non-validated',
        },
      });
      await waitForPromises();

      expect(findTriggerText(findScannerProfileTrigger()).props('text')).toBe('Passive scanner');
      expect(findTriggerText(findSiteProfileTrigger()).props('text')).toBe('Non-validated');
    });
  });

  describe('error handling', () => {
    it('does not emit an error if the profiles are loading', () => {
      createShallowComponent();
      expect(wrapper.emitted('error')).toBeUndefined();
    });

    it('does not emit an error if no profiles are selected', async () => {
      createShallowComponent();
      expect(wrapper.emitted('error')).toBeUndefined();
      await waitForPromises();
      expect(wrapper.emitted('error')).toBeUndefined();
    });

    it('does not emit an error if the profiles selected profiles are valid', async () => {
      const validSiteProfile = siteProfilesFixtures.data.project.siteProfiles.nodes[0].profileName;
      const validScannerProfile =
        scannerProfilesFixtures.data.project.scannerProfiles.nodes[0].profileName;
      createShallowComponent({
        props: {
          savedScannerProfileName: validScannerProfile,
          savedSiteProfileName: validSiteProfile,
        },
      });
      await waitForPromises();
      expect(wrapper.emitted('error')).toBeUndefined();
    });

    it('emits an error if saved profile is invalid', async () => {
      createShallowComponent({
        props: {
          savedScannerProfileName: 'invalidScannerProfileName',
          savedSiteProfileName: 'invalidSiteProfileName',
        },
      });
      expect(wrapper.emitted('error')).toBeUndefined();
      await waitForPromises();
      expect(wrapper.emitted('error')).toHaveLength(2);
    });
  });
});
