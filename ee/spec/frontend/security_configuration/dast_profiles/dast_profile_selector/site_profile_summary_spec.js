import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_summary.vue';
import { siteProfiles } from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';
import DastSiteValidationModal from 'ee/security_configuration/dast_site_validation/components/dast_site_validation_modal.vue';

const [profile] = siteProfiles;
const projectPath = 'group/project';
const scanMethodOption = {
  scanMethod: 'OPENAPI',
  scanFilePath: 'https://example.com',
};

describe('DastScannerProfileSummary', () => {
  let wrapper;

  const createWrapper = (props = {}, glFeatures = {}) => {
    wrapper = shallowMountExtended(App, {
      propsData: {
        profile: {
          ...profile,
          ...scanMethodOption,
        },
        ...props,
      },
      provide: {
        projectPath,
        glFeatures: {
          dastSiteValidationDrawer: true,
          ...glFeatures,
        },
      },
    });
  };

  const findValidateButton = () => wrapper.findByTestId('validation-button');
  const findModal = () => wrapper.findComponent(DastSiteValidationModal);

  it('renders properly', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('when `dastSiteValidationDrawer` is disabled', () => {
    beforeEach(() => {
      createWrapper({
        glFeatures: {
          dastSiteValidationDrawer: false,
        },
      });
    });

    it('validate button should not be visible', () => {
      expect(findValidateButton().exists()).toBe(false);
    });

    it('validation modal should not be present', () => {
      expect(findModal().exists()).toBe(false);
    });
  });
});
