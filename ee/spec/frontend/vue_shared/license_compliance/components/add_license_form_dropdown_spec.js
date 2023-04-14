import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlFormCombobox } from '@gitlab/ui';
import AddLicenseFormDropdown from 'ee/vue_shared/license_compliance/components/add_license_form_dropdown.vue';

describe('AddLicenseFormDropdown', () => {
  let wrapper;
  const KNOWN_LICENSES = ['AGPL-1.0', 'AGPL-3.0', 'Apache 2.0', 'BSD'];

  const findCombobox = () => wrapper.findComponent(GlFormCombobox);

  const createComponent = () => {
    wrapper = shallowMount(AddLicenseFormDropdown, {
      propsData: {
        knownLicenses: KNOWN_LICENSES,
      },
    });
  };

  beforeEach(createComponent);

  it('emits `input` invent on change', async () => {
    const newLicense = 'LGPL';
    findCombobox().vm.$emit('input', newLicense);
    await nextTick();

    expect(wrapper.emitted('update-selected-license')).toEqual([['LGPL']]);
  });

  it('shows all defined licenses', () => {
    expect(findCombobox().exists()).toBe(true);
    expect(findCombobox().props('tokenList')).toEqual(KNOWN_LICENSES);
  });
});
