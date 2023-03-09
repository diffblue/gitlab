import { shallowMount } from '@vue/test-utils';

import DrawerSectionSubHeader from 'ee/compliance_dashboard/components/violations_report/shared/drawer_section_sub_header.vue';

describe('DrawerSectionSubHeader component', () => {
  let wrapper;
  const headerText = 'Section sub header';

  const createComponent = (propsData = {}) => {
    return shallowMount(DrawerSectionSubHeader, {
      propsData,
      slots: {
        default: headerText,
      },
    });
  };

  it('renders the header when not empty', () => {
    wrapper = createComponent({ isEmpty: false });

    expect(wrapper.text()).toBe(headerText);
    expect(wrapper.classes()).toContain('gl-mb-4');
  });

  it('renders the header when empty', () => {
    wrapper = createComponent({ isEmpty: true });

    expect(wrapper.text()).toBe(headerText);
    expect(wrapper.classes()).toContain('gl-mb-0');
  });
});
