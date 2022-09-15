import { GlDropdownSectionHeader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';

import EpicActionsSplitButton from 'ee/related_items_tree/components/epic_issue_actions_split_button.vue';
import createDefaultStore from 'ee/related_items_tree/store';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';

import { mockParentItem } from '../mock_data';

Vue.use(Vuex);

const createComponent = ({ slots, state = {} } = {}) => {
  const store = createDefaultStore();
  store.dispatch('setInitialParentItem', mockParentItem);
  store.state.parentItem.userPermissions.adminEpic = state.adminEpic;

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

      it('renders issue section', () => {
        wrapper = createComponent();

        expect(wrapper.findComponent(GlDropdownSectionHeader).text()).toContain('Issue');
      });

      it.each`
        adminEpic | visible  | headerLength | atIndex | headerText
        ${false}  | ${false} | ${1}         | ${0}    | ${'Issue'}
        ${true}   | ${true}  | ${2}         | ${1}    | ${'Epic'}
      `(
        'epic section is visible=$visible when adminEpic=$adminEpic',
        async ({ adminEpic, headerLength, atIndex, headerText }) => {
          wrapper = createComponent({ state: { adminEpic } });

          await nextTick();

          const els = wrapper.findAllComponents(GlDropdownSectionHeader);

          expect(els).toHaveLength(headerLength);
          expect(els.at(atIndex).text()).toContain(headerText);
        },
      );
    });
  });
});
