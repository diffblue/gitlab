import { shallowMount } from '@vue/test-utils';
import App from 'ee/security_configuration/dast_profiles/dast_profile_selector/site_profile_summary.vue';
import { siteProfiles } from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

const [profile] = siteProfiles;

const scanMethodOption = {
  scanMethod: 'OPENAPI',
  scanFilePath: 'https://example.com',
};

describe('DastScannerProfileSummary', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(App, {
      propsData: {
        profile: {
          ...profile,
          ...scanMethodOption,
        },
        ...props,
      },
      provide: { glFeatures: { dastApiScanner: true } },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders properly', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });
});
