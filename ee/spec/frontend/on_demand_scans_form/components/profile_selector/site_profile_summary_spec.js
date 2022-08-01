import { shallowMount } from '@vue/test-utils';
import App from 'ee/on_demand_scans_form/components/profile_selector/site_profile_summary.vue';
import { siteProfiles } from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

describe('DastSiteProfileSummary', () => {
  let wrapper;

  const createWrapper = (profile = {}) => {
    wrapper = shallowMount(App, {
      propsData: {
        profile,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders properly', () => {
    it.each(siteProfiles)('profile $id $profileName', (profile) => {
      createWrapper(profile);

      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
