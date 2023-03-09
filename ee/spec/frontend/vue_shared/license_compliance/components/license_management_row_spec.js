import { shallowMount } from '@vue/test-utils';

import LicenseManagementRow from 'ee/vue_shared/license_compliance/components/license_management_row.vue';
import { allowedLicense, deniedLicense } from 'ee_jest/vue_shared/license_compliance/mock_data';

let wrapper;

describe('LicenseManagementRow', () => {
  describe('allowed license', () => {
    beforeEach(() => {
      const props = { license: allowedLicense };

      wrapper = shallowMount(LicenseManagementRow, {
        propsData: {
          ...props,
        },
      });
    });

    it('renders the license name', () => {
      expect(wrapper.find('.name').element).toMatchSnapshot();
    });

    it('renders the allowed status text with the status icon', () => {
      expect(wrapper.find('.status').element).toMatchSnapshot();
    });
  });

  describe('denied license', () => {
    beforeEach(() => {
      const props = { license: deniedLicense };

      wrapper = shallowMount(LicenseManagementRow, {
        propsData: {
          ...props,
        },
      });
    });

    it('renders the license name', () => {
      expect(wrapper.find('.name').element).toMatchSnapshot();
    });

    it('renders the denied status text with the status icon', () => {
      expect(wrapper.find('.status').element).toMatchSnapshot();
    });
  });
});
