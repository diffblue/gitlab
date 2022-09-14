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
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('renders issue section', () => {
        expect(wrapper.findComponent(GlDropdownSectionHeader).text()).toContain('Issue');
      });

      it('epic section is hidden when not sufficient permission', async () => {
        wrapper = createComponent({ state: { adminEpic: false } });

        await nextTick();
        const els = wrapper.findAllComponents(GlDropdownSectionHeader);
        expect(els).toHaveLength(1);
        expect(els.at(0).text()).toContain('Issue');
      });

      it('epic section is visible when sufficient permission', async () => {
        wrapper = createComponent({ state: { adminEpic: true } });

        await nextTick();
        const els = wrapper.findAllComponents(GlDropdownSectionHeader);
        expect(els).toHaveLength(2);
        expect(els.at(1).text()).toContain('Epic');
      });
    });
  });
});
