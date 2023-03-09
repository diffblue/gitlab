import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Reference from 'ee/compliance_dashboard/components/violations_report/drawer_sections/reference.vue';
import DrawerSectionHeader from 'ee/compliance_dashboard/components/violations_report/shared/drawer_section_header.vue';

describe('Reference component', () => {
  let wrapper;
  const path = '/path/to/merge_request';
  const reference = '!12345';

  const findSectionHeader = () => wrapper.findComponent(DrawerSectionHeader);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = () => {
    return shallowMount(Reference, {
      propsData: { path, reference },
    });
  };

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the header', () => {
      expect(findSectionHeader().text()).toBe('Merge request');
    });

    it('renders the link', () => {
      expect(findLink().attributes('href')).toBe(path);
      expect(findLink().text()).toBe(reference);
    });
  });
});
