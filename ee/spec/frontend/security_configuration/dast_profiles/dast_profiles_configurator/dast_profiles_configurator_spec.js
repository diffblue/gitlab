import { merge } from 'lodash';
import { GlLink } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import ProfileConflictAlert from 'ee/on_demand_scans_form/components/profile_selector/profile_conflict_alert.vue';
import { s__ } from '~/locale';
import DastProfilesConfigurator from 'ee/security_configuration/dast_profiles/dast_profiles_configurator/dast_profiles_configurator.vue';
import ScannerProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_selector.vue';
import SiteProfileSelector from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_selector.vue';
import ScannerProfileSummary from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_summary.vue';
import SiteProfileSummary from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_summary.vue';
import DastProfilesDrawer from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer.vue';
import DastProfilesDrawerList from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer_list.vue';
import DastProfilesDrawerForm from 'ee/security_configuration/dast_profiles/dast_profiles_drawer/dast_profiles_drawer_form.vue';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import SectionLoader from '~/vue_shared/security_configuration/components/section_loader.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  siteProfiles,
  scannerProfiles,
  nonValidatedSiteProfile,
  validatedSiteProfile,
  passiveScannerProfile,
  activeScannerProfile,
} from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';
import { createMockApolloProvider } from '../graphql/create_mock_apollo_provider';

describe('DastProfilesConfigurator', () => {
  let wrapper;
  const projectPath = 'projectPath';

  const findModal = () => wrapper.findByTestId('dast-profile-form-cancel-modal');
  const findProfileNameInput = () => wrapper.findByTestId('profile-name-input');
  const findEditBtn = () => wrapper.findByTestId('profile-edit-btn');
  const findNewScanButton = () => wrapper.findByTestId('new-profile-button');
  const findOpenDrawerButton = () => wrapper.findByTestId('select-profile-action-btn');
  const findCancelButton = () => wrapper.findByTestId('dast-profile-form-cancel-button');
  const findInUseLabel = () => wrapper.findByTestId('in-use-label');
  const findSectionLayout = () => wrapper.findComponent(SectionLayout);
  const findSectionLoader = () => wrapper.findComponent(SectionLoader);
  const findScannerProfilesSelector = () => wrapper.findComponent(ScannerProfileSelector);
  const findSiteProfilesSelector = () => wrapper.findComponent(SiteProfileSelector);
  const findAllScannerProfileSummary = () => wrapper.findAllComponents(ScannerProfileSummary);
  const findAllSiteProfileSummary = () => wrapper.findAllComponents(SiteProfileSummary);
  const findDastProfileDrawer = () => wrapper.findComponent(DastProfilesDrawer);
  const findDastProfilesDrawerList = () => wrapper.findComponent(DastProfilesDrawerList);
  const findDastProfilesDrawerForm = () => wrapper.findComponent(DastProfilesDrawerForm);
  const findProfilesConflictAlert = () => wrapper.findComponent(ProfileConflictAlert);

  const openDrawer = async () => {
    findOpenDrawerButton().vm.$emit('click');
    await waitForPromises();
  };

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const apolloProvider = createMockApolloProvider();

    wrapper = extendedWrapper(
      mountFn(
        DastProfilesConfigurator,
        merge(
          {},
          {
            propsData: {
              ...options,
            },
            stubs: {
              SectionLayout,
              ScannerProfileSelector,
              SiteProfileSelector,
              GlModal: true,
            },
            provide: {
              projectPath,
            },
          },
          { ...options, apolloProvider },
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
      ),
    );
    return wrapper;
  };
  const createComponent = createComponentFactory(mount);
  const createShallowComponent = createComponentFactory();

  describe('when default state', () => {
    it('renders properly', async () => {
      const sectionHeader = s__('OnDemandScans|DAST configuration');
      createComponent({ configurationHeader: sectionHeader });
      await waitForPromises();

      expect(findSectionLayout().find('h2').text()).toContain(sectionHeader);
      expect(findScannerProfilesSelector().exists()).toBe(true);
      expect(findSiteProfilesSelector().exists()).toBe(true);
    });

    it('renders a link to the docs', () => {
      createComponent();
      const link = findSectionLayout().findComponent(GlLink);

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(
        '/help/user/application_security/dast/index#on-demand-scans',
      );
    });

    it('shows loader in loading state', () => {
      createShallowComponent();

      expect(findSectionLoader().exists()).toBe(true);
    });
  });

  describe('profile drawer', () => {
    beforeEach(async () => {
      createComponent({}, true);
      await waitForPromises();
    });

    it.each`
      findProfileSelector            | findAllProfileSummary           | expectedLength
      ${findScannerProfilesSelector} | ${findAllScannerProfileSummary} | ${scannerProfiles.length}
      ${findSiteProfilesSelector}    | ${findAllSiteProfileSummary}    | ${siteProfiles.length}
    `(
      'should open drawer with profiles',
      async ({ findProfileSelector, findAllProfileSummary, expectedLength }) => {
        findProfileSelector().vm.$emit('open-drawer');
        await waitForPromises();

        expect(findDastProfileDrawer().exists()).toBe(true);
        expect(findAllProfileSummary()).toHaveLength(expectedLength);
      },
    );

    it.each`
      findProfileSelector
      ${findScannerProfilesSelector}
      ${findSiteProfilesSelector}
    `('should open drawer with selected profile in edit mode', async ({ findProfileSelector }) => {
      expect(findDastProfileDrawer().props('open')).toBe(false);
      findProfileSelector().vm.$emit('edit');
      await waitForPromises();

      expect(findDastProfileDrawer().exists()).toBe(true);
      expect(findDastProfilesDrawerForm().exists()).toBe(true);
      expect(findDastProfileDrawer().props('open')).toBe(true);
    });
  });

  describe('saved profiles', () => {
    const savedProfiles = {
      dastScannerProfile: { id: scannerProfiles[0].id },
      dastSiteProfile: { id: siteProfiles[0].id },
    };

    it('should have profiles selected if saved profiles exist', async () => {
      createComponent({ savedProfiles });
      await waitForPromises();

      expect(findScannerProfilesSelector().find('h3').text()).toContain(
        scannerProfiles[0].profileName,
      );
      expect(findSiteProfilesSelector().find('h3').text()).toContain(siteProfiles[0].profileName);
    });
  });

  describe('saved profile names', () => {
    const { profileName: savedScannerProfileName } = scannerProfiles[0];
    const { profileName: savedSiteProfileName } = siteProfiles[0];

    beforeEach(async () => {
      createComponent({ savedSiteProfileName, savedScannerProfileName });
      await waitForPromises();
    });

    it('should have saved profiles selected', () => {
      expect(findScannerProfilesSelector().find('h3').text()).toContain(savedScannerProfileName);
      expect(findSiteProfilesSelector().find('h3').text()).toContain(savedSiteProfileName);
    });

    it('should mark saved profiles as in-use', async () => {
      await openDrawer();
      expect(findInUseLabel().exists()).toBe(true);
    });

    it('should emit open event', async () => {
      await openDrawer();
      expect(wrapper.emitted('open-drawer')).toHaveLength(1);
    });
  });

  describe('switching between modes', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    const expectEditingMode = async () => {
      findNewScanButton().vm.$emit('click');
      await waitForPromises();
      expect(findDastProfilesDrawerForm().exists()).toBe(true);
    };

    it('should have reading mode by default', async () => {
      await openDrawer();

      expect(findDastProfilesDrawerList().exists()).toBe(true);
    });

    it('should have editing mode by default', async () => {
      await openDrawer();
      await expectEditingMode();
    });

    it('should return from editing mode to reading mode', async () => {
      await openDrawer();
      await expectEditingMode();

      findCancelButton().vm.$emit('click');
      await waitForPromises();

      expect(findDastProfilesDrawerList().exists()).toBe(true);
    });
  });

  describe('warning modal', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('should show warning modal when changes are unsaved', async () => {
      findOpenDrawerButton().vm.$emit('click');
      await waitForPromises();

      findEditBtn().vm.$emit('click');
      await waitForPromises();

      findProfileNameInput().vm.$emit('input', 'another value');
      await waitForPromises();

      findOpenDrawerButton().vm.$emit('click');
      await waitForPromises();

      expect(findModal().attributes('visible')).toBe(String(true));
      expect(findModal().attributes('title')).toBe('You have unsaved changes');
    });
  });

  describe.each`
    description                                  | selectedScannerProfile   | selectedSiteProfile        | hasConflict
    ${'a passive scan and a non-validated site'} | ${passiveScannerProfile} | ${nonValidatedSiteProfile} | ${false}
    ${'a passive scan and a validated site'}     | ${passiveScannerProfile} | ${validatedSiteProfile}    | ${false}
    ${'an active scan and a non-validated site'} | ${activeScannerProfile}  | ${nonValidatedSiteProfile} | ${true}
    ${'an active scan and a validated site'}     | ${activeScannerProfile}  | ${validatedSiteProfile}    | ${false}
  `(
    'profiles conflict banner',
    ({ description, selectedScannerProfile, selectedSiteProfile, hasConflict }) => {
      const { profileName: savedScannerProfileName } = selectedScannerProfile;
      const { profileName: savedSiteProfileName } = selectedSiteProfile;

      beforeEach(async () => {
        createComponent({ savedSiteProfileName, savedScannerProfileName }, true);
        await waitForPromises();
      });

      const testDescription = hasConflict
        ? `warns about conflicting profiles when user selects ${description}`
        : `does not report any conflict when user selects ${description}`;

      it(`${testDescription}`, () => {
        expect(findProfilesConflictAlert().exists()).toBe(hasConflict);
      });
    },
  );
});
