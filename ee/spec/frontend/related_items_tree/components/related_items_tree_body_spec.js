import { shallowMount } from '@vue/test-utils';

import RelatedItemsBody from 'ee/related_items_tree/components/related_items_tree_body.vue';

import { mockParentItem } from '../mock_data';

const createComponent = (parentItem = mockParentItem, children = []) =>
  shallowMount(RelatedItemsBody, {
    stubs: {
      'tree-root': true,
    },
    propsData: {
      parentItem,
      children,
    },
  });

describe('RelatedItemsTree', () => {
  describe('RelatedTreeBody', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('template', () => {
      it('renders tree-root component', () => {
        expect(wrapper.find('tree-root-stub').isVisible()).toBe(true);
      });
    });
  });
});
