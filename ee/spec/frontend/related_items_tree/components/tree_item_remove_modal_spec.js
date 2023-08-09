import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';

import TreeItemRemoveModal from 'ee/related_items_tree/components/tree_item_remove_modal.vue';

import { ChildType } from 'ee/related_items_tree/constants';
import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';
import { PathIdSeparator } from '~/related_issues/constants';

import { mockParentItem, mockQueryResponse, mockIssue1, mockEpic1 } from '../mock_data';

Vue.use(Vuex);

const mockItem = {
  ...mockIssue1,
  type: ChildType.Issue,
  pathIdSeparator: PathIdSeparator.Issue,
  assignees: epicUtils.extractIssueAssignees(mockIssue1.assignees),
};

const mockItemWithChildren = {
  ...mockEpic1,
  type: ChildType.Epic,
  pathIdSeparator: PathIdSeparator.Epic,
};

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
  store.dispatch('setRemoveItemModalProps', {
    parentItem,
    item,
  });

  return shallowMount(TreeItemRemoveModal, {
    store,
  });
};

describe('RelatedItemsTree', () => {
  describe('TreeItemRemoveModal', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('template', () => {
      it('renders modal component', () => {
        const modal = wrapper.findComponent(GlModal);

        expect(modal.isVisible()).toBe(true);
        expect(modal.attributes('modalid')).toBe('item-remove-confirmation');
        expect(modal.props('actionPrimary')).toEqual({
          text: 'Remove',
          attributes: { variant: 'danger' },
        });
        expect(modal.props('actionCancel')).toEqual({
          text: 'Cancel',
          attributes: { variant: 'default' },
        });
      });

      it.each`
        type               | modalTitle
        ${ChildType.Epic}  | ${'Remove epic'}
        ${ChildType.Issue} | ${'Remove issue'}
      `('renders modal title when item type is $itemType', ({ type, modalTitle }) => {
        wrapper = createComponent(mockParentItem, { ...mockItem, type });
        const modal = wrapper.findComponent(GlModal);

        expect(modal.props('title')).toBe(modalTitle);
      });

      it('renders modal body message when item has no children present', () => {
        wrapper = createComponent(mockParentItem, { ...mockItem, type: ChildType.Epic });
        const modal = wrapper.findComponent(GlModal);

        expect(modal.text()).toBe(
          `Are you sure you want to remove ${mockItem.title} from ${mockParentItem.title}?`,
        );
      });

      it('renders modal body message when item has children present', () => {
        wrapper = createComponent(mockParentItem, mockItemWithChildren);
        const modal = wrapper.findComponent(GlModal);

        expect(modal.text()).toBe(
          `This will also remove any descendents of ${mockItemWithChildren.title} from ${mockParentItem.title}. Are you sure?`,
        );
      });
    });
  });
});
