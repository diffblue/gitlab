import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import TreeItemRemoveModal from 'ee/related_items_tree/components/tree_item_remove_modal.vue';

import { ChildType } from 'ee/related_items_tree/constants';
import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';
import { PathIdSeparator } from '~/related_issues/constants';

import { mockParentItem, mockQueryResponse, mockIssue1 } from '../mock_data';

Vue.use(Vuex);

const mockItem = {
  ...mockIssue1,
  type: ChildType.Issue,
  pathIdSeparator: PathIdSeparator.Issue,
  assignees: epicUtils.extractIssueAssignees(mockIssue1.assignees),
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

    afterEach(() => {
      wrapper.destroy();
    });

    describe('computed', () => {
      describe('removeItemType', () => {
        it('returns value of `state.removeItemModalProps.item.type', () => {
          expect(wrapper.vm.removeItemType).toBe(mockItem.type);
        });
      });

      describe('modalTitle', () => {
        it('returns title for modal when item.type is `Epic`', () => {
          wrapper.vm.$store.dispatch('setRemoveItemModalProps', {
            parentItem: mockParentItem,
            item: { ...mockItem, type: ChildType.Epic },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.modalTitle).toBe('Remove epic');
          });
        });

        it('returns title for modal when item.type is `Issue`', () => {
          wrapper.vm.$store.dispatch('setRemoveItemModalProps', {
            parentItem: mockParentItem,
            item: mockItem,
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.modalTitle).toBe('Remove issue');
          });
        });
      });

      describe('modalBody', () => {
        it('returns body text for modal when item.type is `Epic`', () => {
          wrapper.vm.$store.dispatch('setRemoveItemModalProps', {
            parentItem: mockParentItem,
            item: { ...mockItem, type: ChildType.Epic },
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.modalBody).toBe(
              'This will also remove any descendents of <b>Nostrum cum mollitia quia recusandae fugit deleniti voluptatem delectus.</b> from <b>Some sample epic</b>. Are you sure?',
            );
          });
        });

        it('returns body text for modal when item.type is `Issue`', () => {
          wrapper.vm.$store.dispatch('setRemoveItemModalProps', {
            parentItem: mockParentItem,
            item: mockItem,
          });

          return wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.modalBody).toBe(
              'Are you sure you want to remove <b>Nostrum cum mollitia quia recusandae fugit deleniti voluptatem delectus.</b> from <b>Some sample epic</b>?',
            );
          });
        });
      });
    });

    describe('template', () => {
      it('renders modal component', () => {
        const modal = wrapper.findComponent(GlModal);

        expect(modal.isVisible()).toBe(true);
        expect(modal.attributes('modalid')).toBe('item-remove-confirmation');
        expect(modal.attributes('ok-title')).toBe('Remove');
        expect(modal.attributes('ok-variant')).toBe('danger');
      });
    });
  });
});
