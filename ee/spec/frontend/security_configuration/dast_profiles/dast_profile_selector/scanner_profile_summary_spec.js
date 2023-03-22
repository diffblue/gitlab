import { shallowMount } from '@vue/test-utils';
import App from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_summary.vue';
import DastProfileSummaryCard from 'ee/security_configuration/dast_profiles/dast_profile_selector/dast_profile_summary_card.vue';
import { scannerProfiles } from 'ee_jest/security_configuration/dast_profiles/mocks/mock_data';

const [profile] = scannerProfiles;

describe('DastScannerProfileSummary', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(App, {
      propsData: {
        profile,
        ...props,
      },
      stubs: {
        DastProfileSummaryCard,
      },
    });
  };

  it('renders properly', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });
});
