import { GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import IssueCardWeight from 'ee/boards/components/issue_card_weight.vue';
import BoardCardInner from '~/boards/components/board_card_inner.vue';
import { issuableTypes } from '~/boards/constants';
import defaultStore from '~/boards/stores';

describe('Board card component', () => {
  let wrapper;
  let issue;
  let list;
  let store;

  const createStore = ({ isShowingLabels = true } = {}) => {
    store = new Vuex.Store({
      ...defaultStore,
      state: {
        ...defaultStore.state,
        issuableType: issuableTypes.issue,
        isShowingLabels,
      },
      getters: {
        isGroupBoard: () => true,
        isEpicBoard: () => false,
        isProjectBoard: () => false,
      },
    });
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(BoardCardInner, {
      store,
      propsData: {
        list,
        item: issue,
        ...props,
      },
      provide: {
        groupId: null,
        rootPath: '/',
        scopedLabelsAvailable: false,
      },
    });
  };

  beforeEach(() => {
    list = {
      id: 300,
      position: 0,
      title: 'Test',
      listType: 'label',
      label: {
        id: 5000,
        title: 'Testing',
        color: '#ff0000',
        description: 'testing;',
        textColor: 'white',
      },
    };

    issue = {
      title: 'Testing',
      id: 1,
      iid: 1,
      confidential: false,
      labels: [list.label],
      assignees: [],
      referencePath: '#1',
      webUrl: '/test/1',
      weight: 1,
      blocked: true,
      blockedByCount: 2,
    };
  });

  beforeEach(() => {
    createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    store = null;
  });

  describe('labels', () => {
    beforeEach(() => {
      const label1 = {
        id: 3,
        title: 'testing 123',
        color: '#000cff',
        textColor: 'white',
        description: 'test',
      };

      issue.labels = [...issue.labels, label1];
    });

    it.each`
      type              | title              | desc
      ${'GroupLabel'}   | ${'Group label'}   | ${'shows group labels on group boards'}
      ${'ProjectLabel'} | ${'Project label'} | ${'shows project labels on group boards'}
    `('$desc', ({ type, title }) => {
      issue.labels = [
        ...issue.labels,
        {
          id: 9001,
          type,
          title,
          color: '#000000',
        },
      ];

      createComponent({ groupId: 1 });

      expect(wrapper.findAllComponents(GlLabel)).toHaveLength(3);
      expect(wrapper.findComponent(GlLabel).props('title')).toContain(title);
    });

    it('shows no labels when the isShowingLabels state is false', () => {
      createStore({ isShowingLabels: false });
      createComponent({});

      expect(wrapper.findAll('.board-card-labels')).toHaveLength(0);
    });
  });

  describe('weight', () => {
    it('shows weight component', () => {
      createComponent();

      expect(wrapper.findComponent(IssueCardWeight).exists()).toBe(true);
    });
  });
});
