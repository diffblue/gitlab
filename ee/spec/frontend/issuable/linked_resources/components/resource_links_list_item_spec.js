import { GlButton, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ResourceLinkItem from 'ee/linked_resources/components/resource_links_list_item.vue';
import API from '~/api';
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

  const findRemoveButton = () => wrapper.findComponent(GlButton);
  const findLinkItem = () => wrapper.findComponent(GlLink);

  describe('template', () => {
    it('matches the snapshot', () => {
      mountComponent();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('does not show the remove button if canRemove=false', () => {
      mountComponent(false);

      expect(findRemoveButton().exists()).toBe(false);
    });

    it('triggers a delete event when the delete button is clicked', async () => {
      mountComponent();

      findRemoveButton().trigger('click');

      await nextTick();

      expect(wrapper.emitted().removeRequest).toHaveLength(1);
    });

    it('calls tracking method when link is clicked', () => {
      jest.spyOn(API, 'trackRedisHllUserEvent');

      mountComponent();

      expect(API.trackRedisHllUserEvent).not.toHaveBeenCalled();

      findLinkItem().trigger('click');

      expect(API.trackRedisHllUserEvent).toHaveBeenCalledWith(
        'incident_management_issuable_resource_link_visited',
      );
    });
  });
});
