import { GlSprintf } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { merge } from 'lodash';
import DastProfilesSelector from 'ee/on_demand_scans_form/components/profile_selector/dast_profiles_selector.vue';
import ConfigurationSnippetModal from 'ee/security_configuration/components/configuration_snippet_modal.vue';
import { CONFIGURATION_SNIPPET_MODAL_ID } from 'ee/security_configuration/components/constants';
import ConfigurationForm from 'ee/security_configuration/dast/components/configuration_form.vue';
import {
  scannerProfiles,
  siteProfiles,
} from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { CODE_SNIPPET_SOURCE_DAST } from '~/pipeline_editor/components/code_snippet_alert/constants';
import { DAST_HELP_PATH } from '~/security_configuration/components/constants';

const [scannerProfile] = scannerProfiles;
const [siteProfile] = siteProfiles;

const securityConfigurationPath = '/security/configuration';
const gitlabCiYamlEditPath = '/ci/editor';
const projectPath = '/project/path';
const siteProfilesLibraryPath = 'siteProfilesLibraryPath';
const scannerProfilesLibraryPath = 'scannerProfilesLibraryPath';
const savedScannerProfile = 'scannerProfile';
const savedSiteProfile = 'siteProfile';

const selectedScannerProfileName = 'My Scan profile';
const selectedSiteProfileName = 'My site profile';

const template = `# Add \`dast\` to your \`stages:\` configuration
stages:
  - dast

# Include the DAST template
include:
  - template: DAST.gitlab-ci.yml

# Your selected site and scanner profiles:
dast:
  stage: dast
  dast_configuration:
    site_profile: "${selectedSiteProfileName}"
    scanner_profile: "${selectedScannerProfileName}"
`;

describe('EE - DAST Configuration Form', () => {
  let wrapper;

  const findSubmitButton = () => wrapper.findByTestId('dast-configuration-submit-button');
  const findCancelButton = () => wrapper.findByTestId('dast-configuration-cancel-button');
  const findConfigurationSnippetModal = () => wrapper.findComponent(ConfigurationSnippetModal);
  const findDastProfilesSelector = () => wrapper.findComponent(DastProfilesSelector);
  const findAlert = () => wrapper.findByTestId('dast-configuration-error');

  const createComponentFactory = (mountFn = shallowMount) => (
    options = {},
    glFeatures = {
      glFeatures: {
        dastUiRedesign: false,
      },
    },
  ) => {
    const defaultMocks = {
      $apollo: {
        queries: {
          siteProfiles: {},
          scannerProfiles: {},
        },
      },
    };

    wrapper = extendedWrapper(
      mountFn(
        ConfigurationForm,
        merge(
          {},
          {
            mocks: defaultMocks,
            provide: {
              securityConfigurationPath,
              gitlabCiYamlEditPath,
              scannerProfilesLibraryPath,
              siteProfilesLibraryPath,
              projectPath,
              scannerProfile: savedScannerProfile,
              siteProfile: savedSiteProfile,
              ...glFeatures,
            },
            stubs: {
              GlSprintf,
            },
          },
          options,
          {
            data() {
              return {
                ...options.data,
              };
            },
          },
        ),
      ),
    );
  };

  const createComponent = createComponentFactory();
  const createFullComponent = createComponentFactory(mount);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('form renders properly', () => {
    beforeEach(() => {
      createComponent();
    });

    it('mounts correctly', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('includes a link to DAST Configuration documentation', () => {
      expect(wrapper.html()).toContain(DAST_HELP_PATH);
    });

    it('loads DAST Profiles Component', () => {
      expect(findDastProfilesSelector().exists()).toBe(true);
    });

    it('does not show an alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('submit button is disabled by default', () => {
      expect(findSubmitButton().props('disabled')).toBe(true);
    });
  });

  describe('error when loading profiles', () => {
    const errorMsg = 'error message';

    beforeEach(async () => {
      createComponent();
      await findDastProfilesSelector().vm.$emit('error', errorMsg);
    });

    it('renders an alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('shows correct error message', () => {
      expect(findAlert().text()).toContain(errorMsg);
    });
  });

  describe.each`
    description                                 | emittedEvent               | emittedValue                       | isDisabled
    ${'when only scanner profile is selected'}  | ${'profiles-selected'}     | ${{ scannerProfile }}              | ${true}
    ${'when only site profile is selected'}     | ${'profiles-selected'}     | ${{ siteProfile }}                 | ${true}
    ${'when both profiles are selected'}        | ${'profiles-selected'}     | ${{ scannerProfile, siteProfile }} | ${false}
    ${'when conflicting profiles are selected'} | ${'profiles-has-conflict'} | ${true}                            | ${true}
    ${'when profiles do not have conflicts'}    | ${'profiles-has-conflict'} | ${false}                           | ${false}
  `('submit button', ({ description, emittedEvent, emittedValue, isDisabled }) => {
    const initialState = {
      data: {
        selectedScannerProfileName: 'scannerProfile.profileName',
        selectedSiteProfileName: 'siteProfile.profileName',
      },
    };
    it(`is ${isDisabled ? '' : 'not '}disabled ${description}`, async () => {
      createComponent(initialState);
      await findDastProfilesSelector().vm.$emit(emittedEvent, emittedValue);
      expect(findSubmitButton().props('disabled')).toBe(isDisabled);
    });
  });

  describe('form actions are configured correctly', () => {
    it('submit button should open the model with correct props', () => {
      createFullComponent({
        data: {
          selectedSiteProfileName,
          selectedScannerProfileName,
        },
      });

      jest.spyOn(wrapper.vm.$refs[CONFIGURATION_SNIPPET_MODAL_ID], 'show');

      wrapper.find('form').trigger('submit');

      expect(wrapper.vm.$refs[CONFIGURATION_SNIPPET_MODAL_ID].show).toHaveBeenCalled();

      expect(findConfigurationSnippetModal().props()).toEqual({
        ciYamlEditUrl: gitlabCiYamlEditPath,
        yaml: template,
        redirectParam: CODE_SNIPPET_SOURCE_DAST,
        scanType: 'DAST',
      });
    });

    it('cancel button points to Security Configuration page', () => {
      createComponent();
      expect(findCancelButton().attributes('href')).toBe(securityConfigurationPath);
    });
  });
});
