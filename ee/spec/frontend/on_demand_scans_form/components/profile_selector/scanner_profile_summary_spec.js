import { shallowMount } from '@vue/test-utils';
import App from 'ee/on_demand_scans_form/components/profile_selector/scanner_profile_summary.vue';
import { scannerProfiles } from 'ee_jest/on_demand_scans_form/mocks/mock_data';

const [profile] = scannerProfiles;

describe('DastScannerProfileSummary', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(App, {
      propsData: {
        profile,
        ...props,
      },
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
