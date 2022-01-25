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

const createComponent = (parentItem = mockParentItem, item = mockItem) => {
  const store = createDefaultStore();
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

  return shallowMount(TreeItem, {
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

describe('RelatedItemsTree', () => {
  describe('TreeItemRemoveModal', () => {
    let wrapper;
    let wrapperExpanded;
    let wrapperCollapsed;

    beforeEach(() => {
      wrapper = createComponent();
    });

    beforeAll(() => {
      wrapperExpanded = createComponent();
      wrapperExpanded.vm.$store.dispatch('expandItem', {
        parentItem: mockItem,
      });

      wrapperCollapsed = createComponent();
      wrapperCollapsed.vm.$store.dispatch('collapseItem', {
        parentItem: mockItem,
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    afterAll(() => {
      wrapperExpanded.destroy();
      wrapperCollapsed.destroy();
    });

    describe('computed', () => {
      describe('itemReference', () => {
        it('returns value of `item.reference`', () => {
          expect(wrapper.vm.itemReference).toBe(mockItem.reference);
        });
      });

      describe('chevronType', () => {
        it('returns string `chevron-down` when `state.childrenFlags[itemReference].itemExpanded` is true', () => {
          expect(wrapperExpanded.vm.chevronType).toBe('chevron-down');
        });

        it('returns string `chevron-right` when `state.childrenFlags[itemReference].itemExpanded` is false', () => {
          expect(wrapperCollapsed.vm.chevronType).toBe('chevron-right');
        });
      });

      describe('chevronTooltip', () => {
        it('returns string `Collapse` when `state.childrenFlags[itemReference].itemExpanded` is true', () => {
          expect(wrapperExpanded.vm.chevronTooltip).toBe('Collapse');
        });

        it('returns string `Expand` when `state.childrenFlags[itemReference].itemExpanded` is false', () => {
          expect(wrapperCollapsed.vm.chevronTooltip).toBe('Expand');
        });
      });
    });

    describe('methods', () => {
      describe('handleChevronClick', () => {
        it('calls `toggleItem` action with `item` as a param', () => {
          jest.spyOn(wrapper.vm, 'toggleItem');

          wrapper.vm.handleChevronClick();

          expect(wrapper.vm.toggleItem).toHaveBeenCalledWith({
            parentItem: mockItem,
          });
        });
      });
    });

    describe('template', () => {
      it('renders list item as component container element', () => {
        expect(wrapper.vm.$el.classList.contains('tree-item')).toBe(true);
        expect(wrapper.vm.$el.classList.contains('js-item-type-epic')).toBe(true);
        expect(wrapperExpanded.vm.$el.classList.contains('item-expanded')).toBe(true);
      });

      it('renders expand/collapse button', () => {
        const chevronButton = wrapper.findComponent(GlButton);

        expect(chevronButton.isVisible()).toBe(true);
        expect(chevronButton.attributes('title')).toBe('Collapse');
      });

      it('has the proper class on the expand/collapse button to avoid dragging', () => {
        const chevronButton = wrapper.findComponent(GlButton);

        expect(chevronButton.attributes('class')).toContain(treeItemChevronBtnClassName);
      });

      it('renders expand/collapse icon', () => {
        const expandedIcon = wrapperExpanded.findComponent(GlIcon);
        const collapsedIcon = wrapperCollapsed.findComponent(GlIcon);

        expect(expandedIcon.isVisible()).toBe(true);
        expect(expandedIcon.props('name')).toBe('chevron-down');
        expect(collapsedIcon.isVisible()).toBe(true);
        expect(collapsedIcon.props('name')).toBe('chevron-right');
      });

      it('renders loading icon when item expand is in progress', async () => {
        wrapper.vm.$store.dispatch('requestItems', {
          parentItem: mockItem,
          isSubItem: true,
        });

        await nextTick();
        const loadingIcon = wrapper.findComponent(GlLoadingIcon);

        expect(loadingIcon.isVisible()).toBe(true);
      });

      it('renders tree item body component', () => {
        const itemBody = wrapper.findComponent(TreeItemBody);

        expect(itemBody.isVisible()).toBe(true);
      });
    });
  });
});
