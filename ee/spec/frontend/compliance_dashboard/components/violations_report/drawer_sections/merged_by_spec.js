import { GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import MergedBy from 'ee/compliance_dashboard/components/violations_report/drawer_sections/merged_by.vue';
import DrawerSectionHeader from 'ee/compliance_dashboard/components/violations_report/shared/drawer_section_header.vue';
import DrawerSectionSubHeader from 'ee/compliance_dashboard/components/violations_report/shared/drawer_section_sub_header.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createUser } from '../../../mock_data';

describe('MergedBy component', () => {
  let wrapper;

  const findSectionHeader = () => wrapper.findComponent(DrawerSectionHeader);
  const findSubHeader = () => wrapper.findComponent(DrawerSectionSubHeader);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findAvatarLabel = () => wrapper.findComponent(GlAvatarLabeled);

  const createComponent = (propsData = {}) => {
    return shallowMountExtended(MergedBy, {
      propsData,
    });
  };

  describe('without the merged by user', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the header', () => {
      expect(findSectionHeader().text()).toBe('Merged by');
    });

    it('does not render the list', () => {
      expect(findAvatarLink().exists()).toBe(false);
      expect(findAvatarLabel().exists()).toBe(false);
    });

    it('does render the empty text', () => {
      expect(findSubHeader().text()).toBe('Unknown user');
      expect(findSubHeader().props('isEmpty')).toBe(true);
    });
  });

  describe('with the merged by user', () => {
    const mergedBy = createUser(1);

    beforeEach(() => {
      wrapper = createComponent({ mergedBy });
    });

    it('renders the header', () => {
      expect(findSectionHeader().text()).toBe('Merged by');
    });

    it('renders the list', () => {
      expect(findAvatarLink().classes()).toContain('js-user-link');
      expect(findAvatarLink().attributes()).toMatchObject({
        title: mergedBy.name,
        href: mergedBy.webUrl,
        'data-name': mergedBy.name,
        'data-user-id': `${mergedBy.id}`,
      });

      expect(findAvatarLabel().props()).toMatchObject({
        subLabel: mergedBy.name,
        label: '',
      });
      expect(findAvatarLabel().attributes()).toMatchObject({
        'entity-name': mergedBy.name,
        src: mergedBy.avatarUrl,
      });
    });

    it('does not render the empty text', () => {
      expect(findSubHeader().exists()).toBe(false);
    });
  });
});
