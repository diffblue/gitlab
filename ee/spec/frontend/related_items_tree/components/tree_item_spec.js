import { GlButton, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';

import TreeItem from 'ee/related_items_tree/components/tree_item.vue';
import TreeItemBody from 'ee/related_items_tree/components/tree_item_body.vue';
import TreeRoot from 'ee/related_items_tree/components/tree_root.vue';

import { ChildType, treeItemChevronBtnClassName } from 'ee/related_items_tree/constants';
import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';
import { PathIdSeparator } from '~/related_issues/constants';

import { mockParentItem, mockQueryResponse, mockEpic1 } from '../mock_data';

const mockItem = { ...mockEpic1, type: ChildType.Epic, pathIdSeparator: PathIdSeparator.Epic };

Vue.use(Vuex);

describe('RelatedItemsTree', () => {
  describe('TreeItemRemoveModal', () => {
    let wrapper;
    let store;

    const createComponent = (parentItem = mockParentItem, item = mockItem) => {
      store = createDefaultStore();
      const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

      store.dispatch('setInitialParentItem', mockParentItem);
      store.dispatch('setItemChildren', {
        parentItem: mockParentItem,
        isSubItem: false,
        children,
      });
      store.dispatch('setItemChildrenFlags', {
        isSubItem: false,
        children,
      });
      store.dispatch('setItemChildren', {
        parentItem: mockItem,
        children: [],
        isSubItem: true,
      });

      wrapper = shallowMount(TreeItem, {
        store,
        stubs: {
          'tree-root': TreeRoot,
        },
        propsData: {
          parentItem,
          item,
        },
      });
    };

    const findChevronButton = () => wrapper.findComponent(GlButton);
    const findChevronIcon = () => wrapper.findComponent(GlIcon);
    const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
    const findTreeItemBody = () => wrapper.findComponent(TreeItemBody);

    beforeEach(() => {
      createComponent();
    });

    describe('loading', () => {
      it('renders loading icon when item expand is in progress', async () => {
        store.dispatch('requestItems', {
          parentItem: mockItem,
          isSubItem: true,
        });

        await nextTick();

        expect(findLoadingIcon().isVisible()).toBe(true);
      });
    });

    describe('default', () => {
      it('has the proper class on the expand/collapse button to avoid dragging', () => {
        expect(findChevronButton().attributes('class')).toContain(treeItemChevronBtnClassName);
      });

      it('calls `toggleItem` action with `item` as a param when clicked', async () => {
        jest.spyOn(store, 'dispatch');

        await findChevronButton().vm.$emit('click');

        expect(store.dispatch).toHaveBeenCalledWith('toggleItem', {
          parentItem: mockItem,
        });
      });

      it('renders tree item body component', () => {
        expect(findTreeItemBody().isVisible()).toBe(true);
      });

      it('renders list item as component container element', () => {
        expect(wrapper.classes()).toContain('tree-item', 'js-item-type-epic');
      });
    });

    describe('expanded', () => {
      it('displays the correct chevronType', () => {
        expect(findChevronIcon().isVisible()).toBe(true);
        expect(findChevronIcon().props('name')).toBe('chevron-down');
        expect(findChevronButton().classes('chevron-down')).toBe(true);
      });

      it('displays the correct chevronTooltip', () => {
        expect(findChevronButton().isVisible()).toBe(true);
        expect(findChevronButton().attributes('title')).toBe('Collapse');
      });

      it('adds "item-expanded" class to the wrapper', () => {
        expect(wrapper.classes()).toContain('item-expanded');
      });
    });

    describe('collapsed', () => {
      beforeEach(() => {
        store.dispatch('collapseItem', {
          parentItem: mockItem,
        });
      });

      it('displays the correct chevronType', () => {
        expect(findChevronIcon().isVisible()).toBe(true);
        expect(findChevronIcon().props('name')).toBe('chevron-right');
        expect(findChevronButton().classes('chevron-right')).toBe(true);
      });

      it('displays the correct chevronTooltip', () => {
        expect(findChevronButton().isVisible()).toBe(true);
        expect(findChevronButton().attributes('title')).toBe('Expand');
      });

      it('adds "item-expanded" class to the wrapper', () => {
        expect(wrapper.classes()).not.toContain('item-expanded');
      });
    });
  });
});
