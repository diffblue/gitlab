import { shallowMount } from '@vue/test-utils';

import DrawerSectionHeader from 'ee/compliance_dashboard/components/violations_report/shared/drawer_section_header.vue';

describe('DrawerSectionHeader component', () => {
  let wrapper;
  const headerText = 'Section header';

  const createComponent = () => {
    return shallowMount(DrawerSectionHeader, {
      slots: {
        default: headerText,
      },
    });
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders the header text', () => {
    expect(wrapper.text()).toBe(headerText);
  });
});
