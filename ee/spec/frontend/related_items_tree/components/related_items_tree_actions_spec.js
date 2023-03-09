import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ToggleLabels from 'ee/boards/components/toggle_labels.vue';
import RelatedItemsTreeActions from 'ee/related_items_tree/components/related_items_tree_actions.vue';
import { ITEM_TABS } from 'ee/related_items_tree/constants';
import createDefaultStore from 'ee/related_items_tree/store';

import { mockInitialConfig } from '../mock_data';

Vue.use(Vuex);

const createComponent = ({ slots } = {}) => {
  const store = createDefaultStore();
  store.dispatch('setInitialConfig', mockInitialConfig);

  return shallowMountExtended(RelatedItemsTreeActions, {
    store,
    slots,
    propsData: {
      activeTab: ITEM_TABS.TREE,
    },
  });
};

describe('RelatedItemsTree', () => {
  describe('RelatedItemsTreeActions', () => {
    let wrapper;

    describe('template', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('renders button group, tree view and roadmap view buttons', () => {
        expect(wrapper.element).toMatchSnapshot();
      });

      it('does not render roadmap view button when subEpics are not present', async () => {
        wrapper.vm.$store.dispatch('setInitialConfig', {
          ...mockInitialConfig,
          allowSubEpics: false,
        });

        await nextTick();

        const roadmapViewEl = wrapper.findByTestId('roadmap-view-button');

        expect(roadmapViewEl.exists()).toBe(false);
      });

      describe('ToggleLabels', () => {
        it('renders when view is tree', () => {
          expect(wrapper.findComponent(ToggleLabels).exists()).toBe(true);
        });
        it('does not render when view is roadmap', async () => {
          await wrapper.setProps({ activeTab: ITEM_TABS.ROADMAP });
          expect(wrapper.findComponent(ToggleLabels).exists()).toBe(false);
        });
      });
    });

    describe('emit tab-change', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it.each`
        viewName          | testid                   | name
        ${'tree view'}    | ${'tree-view-button'}    | ${ITEM_TABS.TREE}
        ${'roadmap view'} | ${'roadmap-view-button'} | ${ITEM_TABS.ROADMAP}
      `('emits tab-change event when $viewName button is clicked', ({ testid, name }) => {
        const button = wrapper.findByTestId(testid);

        button.vm.$emit('click');

        expect(wrapper.emitted('tab-change')[0]).toEqual([name]);
      });
    });
  });
});
