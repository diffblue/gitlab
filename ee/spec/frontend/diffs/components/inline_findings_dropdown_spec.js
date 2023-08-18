import { GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import inlineFindingsDropdown from 'ee/diffs/components/inline_findings_dropdown.vue';

import {
  singularCodeQualityFinding,
  singularSastFinding,
  dropdownIcon,
} from 'jest/diffs/mock_data/inline_findings';

let wrapper;
const findIcon = () => wrapper.findByTestId('toggle-icon');
const findGlDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

const createComponent = () => {
  const payload = {
    propsData: {
      items: [
        {
          name: '1 Code Quality finding detected',
          items: singularCodeQualityFinding,
        },
        {
          name: '1 SAST finding detected',
          items: singularSastFinding,
        },
      ],

      iconId: dropdownIcon.id,
      iconKey: dropdownIcon.key,
      iconName: dropdownIcon.name,
      iconClass: dropdownIcon.class,
    },
  };
  wrapper = mountExtended(inlineFindingsDropdown, payload);
};

describe('inlineFindingsDropdown', () => {
  it('renders gl-disclosure-dropdown with correct props', () => {
    createComponent();
    expect(wrapper.exists()).toBe(true);
    expect(findGlDisclosureDropdown().props('items')).toEqual(wrapper.vm.items);
  });

  it('emits mouseenter and mouseleave events on toggle hover', () => {
    createComponent();

    findIcon().trigger('mouseenter');
    findIcon().trigger('mouseleave');

    expect(wrapper.emitted('mouseenter')).toHaveLength(1);
    expect(wrapper.emitted('mouseleave')).toHaveLength(1);
  });
});
