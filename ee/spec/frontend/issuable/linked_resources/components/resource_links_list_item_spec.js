import { GlIcon, GlButton, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ResourceLinkItem from 'ee/linked_resources/components/resource_links_list_item.vue';
import { resourceLinksListI18n } from 'ee/linked_resources/constants';
import { mockResourceLinks } from './mock_data';

describe('ResourceLinkItem', () => {
  let wrapper;

  const mountComponent = (canRemove = true) => {
    const { link, linkType, linkText } = mockResourceLinks[0];
    wrapper = mountExtended(ResourceLinkItem, {
      propsData: {
        linkText,
        canRemove,
        linkValue: link,
        iconName: linkType,
      },
    });
  };

  const findLinkTypeIcon = () => wrapper.findComponent(GlIcon);
  const findLinkText = () => wrapper.findComponent(GlLink);
  const findRemoveButton = () => wrapper.findComponent(GlButton);

  describe('template', () => {
    it('matches the snapshot', () => {
      mountComponent();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('does not show the remove button if canRemove=false', () => {
      mountComponent(false);

      expect(findRemoveButton().exists()).toBe(false);
    });
  });
});
