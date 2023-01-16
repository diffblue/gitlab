import { GlDropdownSectionHeader, GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';

import EpicActionsSplitButton from 'ee/related_items_tree/components/epic_issue_actions_split_button.vue';
import createDefaultStore from 'ee/related_items_tree/store';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

import { mockParentItem } from '../mock_data';

Vue.use(Vuex);

const createComponent = ({ slots, state = {} } = {}) => {
  const store = createDefaultStore();
  store.dispatch('setInitialParentItem', {
    ...mockParentItem,
    userPermissions: {
      ...mockParentItem.userPermissions,
      canAdmin: state.canAdmin,
      canAdminRelation: state.canAdminRelation,
    },
  });

  return extendedWrapper(
    mount(EpicActionsSplitButton, {
      store,
      slots,
      propsData: {
        allowSubEpics: true,
      },
    }),
  );
};

describe('RelatedItemsTree', () => {
  describe('EpicActionsSplitButton', () => {
    describe('template', () => {
      let wrapper;

      beforeEach(() => {
        wrapper = createComponent({ state: { canAdmin: true, canAdminRelation: true } });
      });

      it.each`
        index | headerText
        ${0}  | ${'Issue'}
        ${1}  | ${'Epic'}
      `('renders "$headerText" section header', ({ index, headerText }) => {
        expect(wrapper.findAllComponents(GlDropdownSectionHeader).at(index).text()).toContain(
          headerText,
        );
      });

      it('does not render entire "Epic" section when `parentItem.userPermissions.canAdminRelation` is false', () => {
        wrapper = createComponent({ state: { canAdminRelation: false } });

        expect(wrapper.findAllComponents(GlDropdownSectionHeader)).toHaveLength(1);
        expect(wrapper.findAllComponents(GlDropdownItem)).toHaveLength(2);
      });

      it.each`
        index | actionText
        ${0}  | ${'Add a new issue'}
        ${1}  | ${'Add an existing issue'}
        ${2}  | ${'Add a new epic'}
        ${3}  | ${'Add an existing epic'}
      `('renders "$actionText" action', ({ index, actionText }) => {
        expect(wrapper.findAllComponents(GlDropdownItem).at(index).text()).toContain(actionText);
      });

      it('does not render "Add a new epic" action when `parentItem.userPermissions.canAdmin` is false', () => {
        wrapper = createComponent({ state: { canAdmin: false, canAdminRelation: true } });

        expect(wrapper.findAllComponents(GlDropdownItem)).toHaveLength(3);
        expect(wrapper.findAllComponents(GlDropdownItem).at(2).text()).not.toContain(
          'Add a new epic',
        );
      });
    });
  });
});
