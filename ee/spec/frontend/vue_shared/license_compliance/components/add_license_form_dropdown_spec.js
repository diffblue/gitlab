import { shallowMount } from '@vue/test-utils';
import $ from 'jquery';
import Dropdown from 'ee/vue_shared/license_compliance/components/add_license_form_dropdown.vue';
import waitForPromises from 'helpers/wait_for_promises';

let vm;
let wrapper;

const KNOWN_LICENSES = ['AGPL-1.0', 'AGPL-3.0', 'Apache 2.0', 'BSD'];

const createComponent = async (props = {}) => {
  wrapper = shallowMount(Dropdown, { propsData: { knownLicenses: KNOWN_LICENSES, ...props } });
  await waitForPromises();
  vm = wrapper.vm;
};

describe('AddLicenseFormDropdown', () => {
  afterEach(() => {
    vm = undefined;
    wrapper.destroy();
  });

  it('emits `input` invent on change', async () => {
    await createComponent();

    jest.spyOn(vm, '$emit').mockImplementation(() => {});

    $(vm.$el).val('LGPL').trigger('change');

    expect(vm.$emit).toHaveBeenCalledWith('input', 'LGPL');
  });

  it('sets the placeholder appropriately', async () => {
    const placeholder = 'Select a license';
    await createComponent({ placeholder });

    const dropdownContainer = $(vm.$el).select2('container')[0];

    expect(dropdownContainer.textContent).toContain(placeholder);
  });

  it('sets the initial value correctly', async () => {
    const value = 'AWESOME_LICENSE';
    await createComponent({ value });

    expect(vm.$el.value).toContain(value);
  });

  it('shows all defined licenses', async () => {
    await createComponent();

    const element = $(vm.$el);

    element.on('select2-open', () => {
      const options = $('.select2-drop .select2-result');

      expect(KNOWN_LICENSES).toHaveLength(options.length);
      options.each((index, optionEl) => {
        expect(KNOWN_LICENSES).toContain($(optionEl).text());
      });
    });

    element.select2('open');
  });
});
