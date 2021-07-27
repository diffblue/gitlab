import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import BoardScope from 'ee/boards/components/board_scope.vue';
import { useMockIntersectionObserver } from 'helpers/mock_dom_observer';
import { TEST_HOST } from 'helpers/test_constants';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

Vue.use(Vuex);

describe('BoardScope', () => {
  let wrapper;
  let store;
  useMockIntersectionObserver();

  const createStore = () => {
    return new Vuex.Store({
      getters: {
        isIssueBoard: () => true,
        isEpicBoard: () => false,
      },
    });
  };

  function mountComponent() {
    wrapper = mount(BoardScope, {
      store,
      propsData: {
        collapseScope: false,
        canAdminBoard: false,
        board: {
          labels: [],
          assignee: {},
        },
        labelsPath: `${TEST_HOST}/labels`,
        labelsWebUrl: `${TEST_HOST}/-/labels`,
      },
      stubs: {
        AssigneeSelect: true,
      },
    });
  }

  beforeEach(() => {
    store = createStore();
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findLabelSelect = () => wrapper.findComponent(LabelsSelect);

  describe('ee/app/assets/javascripts/boards/components/board_scope.vue', () => {
    it('emits selected labels to be added and removed from the board', async () => {
      const labels = [{ id: '1', set: true, color: '#BADA55', text_color: '#FFFFFF' }];
      expect(findLabelSelect().exists()).toBe(true);
      expect(findLabelSelect().text()).toContain('Any label');
      expect(findLabelSelect().props('selectedLabels')).toHaveLength(0);
      findLabelSelect().vm.$emit('updateSelectedLabels', labels);
      await nextTick();
      expect(wrapper.emitted('set-board-labels')).toEqual([[labels]]);
    });
  });
});
