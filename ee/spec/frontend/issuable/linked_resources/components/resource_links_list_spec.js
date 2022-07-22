import ResourceLinksList from 'ee/linked_resources/components/resource_links_list.vue';
import ResourceLinkItem from 'ee/linked_resources/components/resource_links_list_item.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { mockResourceLinks } from './mock_data';

describe('ResourceLinksList', () => {
  let wrapper;

  const mountComponent = (resourceLinks = [], isFormVisible = false) => {
    wrapper = mountExtended(ResourceLinksList, {
      propsData: {
        canAdmin: true,
        resourceLinks,
        isFormVisible,
      },
    });
  };

  const findAllLinkListItems = () => wrapper.findAllComponents(ResourceLinkItem);
  const findLinkList = () => wrapper.findByTestId('resource-link-list');

  describe('template', () => {
    it('does not add border class when form is not visible and list is shown', () => {
      mountComponent(mockResourceLinks);

      expect(findAllLinkListItems()).toHaveLength(3);
      expect(findLinkList().classes()).not.toContain('bordered-box');
    });

    it('adds border class when form is visible', () => {
      mountComponent(mockResourceLinks, true);

      expect(findAllLinkListItems()).toHaveLength(3);
      expect(findLinkList().classes()).toContain('bordered-box');
    });
  });
});
