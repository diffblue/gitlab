import { GlButton, GlButtonGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';

import BoardListHeader from 'ee/boards/components/board_list_header.vue';
import defaultGetters from 'ee/boards/stores/getters';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { boardListQueryResponse, mockList, mockLabelList } from 'jest/boards/mock_data';
import { ListType, inactiveId } from '~/boards/constants';
import boardsEventHub from '~/boards/eventhub';
import listQuery from 'ee/boards/graphql/board_lists_deferred.query.graphql';
import sidebarEventHub from '~/sidebar/event_hub';

Vue.use(VueApollo);
Vue.use(Vuex);

const listMocks = {
  [ListType.assignee]: {
    assignee: {},
  },
  [ListType.iteration]: {
    iteration: {
      startDate: '2021-11-01',
      dueDate: '2021-11-05',
    },
  },
  [ListType.label]: {
    ...mockLabelList,
  },
  [ListType.backlog]: {
    ...mockList,
  },
};

describe('Board List Header Component', () => {
  let store;
  let wrapper;
  let fakeApollo;

  beforeEach(() => {
    store = new Vuex.Store({ state: { activeId: inactiveId }, defaultGetters });
  });

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;

    localStorage.clear();
  });

  const createComponent = ({
    listType = ListType.backlog,
    collapsed = false,
    withLocalStorage = true,
    isSwimlanesHeader = false,
    weightFeatureAvailable = false,
    listQueryHandler = jest.fn().mockResolvedValue(boardListQueryResponse()),
    currentUserId = 1,
    state = { activeId: inactiveId },
    getters = {},
    glFeatures = {},
  } = {}) => {
    const boardId = '1';

    const listMock = {
      ...listMocks[listType],
      listType,
      collapsed,
    };

    if (withLocalStorage) {
      localStorage.setItem(
        `boards.${boardId}.${listMock.listType}.${listMock.id}.expanded`,
        (!collapsed).toString(),
      );
    }

    fakeApollo = createMockApollo([[listQuery, listQueryHandler]]);
    store = new Vuex.Store({
      state,
      getters: {
        ...defaultGetters,
        ...getters,
      },
    });

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(BoardListHeader, {
      apolloProvider: fakeApollo,
      store,
      propsData: {
        disabled: false,
        list: listMock,
        isSwimlanesHeader,
      },
      provide: {
        boardId,
        weightFeatureAvailable,
        currentUserId,
        glFeatures,
      },
    });
  };

  const findSettingsButton = () => wrapper.findComponent({ ref: 'settingsBtn' });
  const findIterationPeriod = () => wrapper.find('[data-testid="board-list-iteration-period"]');

  afterEach(() => {
    wrapper.destroy();

    localStorage.clear();
  });

  describe('New epic button', () => {
    let newEpicButton;

    beforeEach(() => {
      jest.spyOn(boardsEventHub, '$emit');
      createComponent({
        getters: {
          isIssueBoard: () => false,
          isEpicBoard: () => true,
          isGroupBoard: () => true,
        },
      });
      newEpicButton = wrapper.findComponent(GlButtonGroup).findComponent(GlButton);
    });

    it('renders New epic button', () => {
      expect(newEpicButton.exists()).toBe(true);
      expect(newEpicButton.attributes()).toMatchObject({
        title: 'New epic',
        'aria-label': 'New epic',
      });
    });

    it('emits `toggle-epic-form` event on Sidebar eventHub when clicked', async () => {
      await newEpicButton.vm.$emit('click');

      expect(boardsEventHub.$emit).toHaveBeenCalledWith(`toggle-epic-form-${mockList.id}`);
      expect(boardsEventHub.$emit).toHaveBeenCalledTimes(1);
    });
  });

  describe('Settings Button', () => {
    const hasSettings = [ListType.assignee, ListType.milestone, ListType.iteration, ListType.label];
    const hasNoSettings = [ListType.backlog, ListType.closed];

    it.each(hasSettings)('does render for List Type `%s`', (listType) => {
      createComponent({ listType });

      expect(findSettingsButton().exists()).toBe(true);
    });

    it.each(hasNoSettings)('does not render for List Type `%s`', (listType) => {
      createComponent({ listType });

      expect(findSettingsButton().exists()).toBe(false);
    });

    it('has a test for each list type', () => {
      createComponent();

      Object.values(ListType).forEach((value) => {
        expect([...hasSettings, ...hasNoSettings]).toContain(value);
      });
    });

    describe('emits sidebar.closeAll event on openSidebarSettings', () => {
      beforeEach(() => {
        jest.spyOn(sidebarEventHub, '$emit');
      });

      it('emits event if no active List', () => {
        // Shares the same behavior for any settings-enabled List type
        createComponent({ listType: hasSettings[0] });
        wrapper.vm.openSidebarSettings();

        expect(sidebarEventHub.$emit).toHaveBeenCalledWith('sidebar.closeAll');
      });

      it('does not emit event when there is an active List', () => {
        createComponent({
          listType: hasSettings[0],
          state: {
            activeId: mockLabelList.id,
          },
        });
        wrapper.vm.openSidebarSettings();

        expect(sidebarEventHub.$emit).not.toHaveBeenCalled();
      });
    });
  });

  describe('Swimlanes header', () => {
    it('when collapsed, it displays info icon', () => {
      createComponent({ isSwimlanesHeader: true, collapsed: true });

      expect(wrapper.find('.board-header-collapsed-info-icon').exists()).toBe(true);
    });
  });

  describe('weightFeatureAvailable', () => {
    it('weightFeatureAvailable is true', async () => {
      createComponent({ weightFeatureAvailable: true });

      await waitForPromises();

      const weightTooltip = wrapper.findComponent({ ref: 'weightTooltip' });

      expect(weightTooltip.exists()).toBe(true);
      expect(weightTooltip.text()).toContain(boardListQueryResponse().data.boardList.totalWeight);
    });

    it('weightFeatureAvailable is false', () => {
      createComponent();

      expect(wrapper.findComponent({ ref: 'weightTooltip' }).exists()).toBe(false);
    });
  });

  describe('iteration cadence', () => {
    describe('iteration_cadences feature flag is on', () => {
      it('displays iteration period', () => {
        createComponent({
          listType: ListType.iteration,
          glFeatures: {
            iterationCadences: true,
          },
        });

        expect(findIterationPeriod().text()).toContain('Nov 1, 2021 - Nov 5, 2021');
        expect(findIterationPeriod().isVisible()).toBe(true);
      });
    });

    describe('iteration_cadences feature flag is off', () => {
      it('does not display iteration period', () => {
        createComponent({ listType: ListType.iteration });

        expect(findIterationPeriod().exists()).toBe(false);
      });
    });
  });
});
