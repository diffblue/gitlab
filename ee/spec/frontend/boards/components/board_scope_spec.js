import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import BoardScope from 'ee/boards/components/board_scope.vue';
import { TEST_HOST } from 'helpers/test_constants';
import LabelsSelect from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';

Vue.use(Vuex);

describe('BoardScope', () => {
  let wrapper;
  let store;

  const createStore = ({ isIssueBoard }) => {
    return new Vuex.Store({
      getters: {
        isIssueBoard: () => isIssueBoard,
        isEpicBoard: () => !isIssueBoard,
      },
    });
  };

  function mountComponent({ isIssueBoard = true } = []) {
    store = createStore({ isIssueBoard });
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
        BoardMilestoneSelect: true,
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findLabelSelect = () => wrapper.findComponent(LabelsSelect);

  describe('BoardScope', () => {
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

  it.each`
    isIssueBoard | text
    ${true}      | ${'Board scope affects which issues are displayed for anyone who visits this board'}
    ${false}     | ${'Board scope affects which epics are displayed for anyone who visits this board'}
  `('displays $text when isIssueBoard is $isIssueBoard', ({ isIssueBoard, text }) => {
    mountComponent({ isIssueBoard });
    expect(wrapper.find('p.text-secondary').text()).toEqual(text);
  });
});
