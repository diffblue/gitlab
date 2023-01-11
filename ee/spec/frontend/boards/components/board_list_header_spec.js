import { GlButton, GlButtonGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import BoardListHeader from 'ee/boards/components/board_list_header.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  boardListQueryResponse,
  epicBoardListQueryResponse,
  mockList,
  mockLabelList,
} from 'jest/boards/mock_data';
import { ListType, inactiveId } from '~/boards/constants';
import boardsEventHub from '~/boards/eventhub';
import listQuery from 'ee/boards/graphql/board_lists_deferred.query.graphql';
import epicListQuery from 'ee/boards/graphql/epic_board_lists_deferred.query.graphql';
import sidebarEventHub from '~/sidebar/event_hub';

Vue.use(VueApollo);
Vue.use(Vuex);

const listMocks = {
  [ListType.assignee]: {
    assignee: {},
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
    store = new Vuex.Store({ state: { activeId: inactiveId } });
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
    canCreateEpic = true,
    listQueryHandler = jest.fn().mockResolvedValue(boardListQueryResponse()),
    glFeatures = { feEpicBoardTotalWeight: true },
    currentUserId = 1,
    state = { activeId: inactiveId },
    isEpicBoard = false,
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

    fakeApollo = createMockApollo([
      [listQuery, listQueryHandler],
      [epicListQuery, jest.fn().mockResolvedValue(epicBoardListQueryResponse())],
    ]);

    store = new Vuex.Store({
      state,
    });

    jest.spyOn(store, 'dispatch').mockImplementation();

    wrapper = shallowMount(BoardListHeader, {
      apolloProvider: fakeApollo,
      store,
      propsData: {
        list: listMock,
        isSwimlanesHeader,
      },
      provide: {
        boardId,
        weightFeatureAvailable,
        currentUserId,
        canCreateEpic,
        glFeatures,
        isEpicBoard,
        disabled: false,
      },
    });
  };

  const findSettingsButton = () => wrapper.findComponent({ ref: 'settingsBtn' });

  afterEach(() => {
    wrapper.destroy();

    localStorage.clear();
  });

  describe('New epic button', () => {
    let newEpicButton;

    beforeEach(() => {
      jest.spyOn(boardsEventHub, '$emit');
      createComponent({ isEpicBoard: true });
      newEpicButton = wrapper.findComponent(GlButtonGroup).findComponent(GlButton);
    });

    it('renders New epic button', () => {
      expect(newEpicButton.exists()).toBe(true);
      expect(newEpicButton.attributes()).toMatchObject({
        title: 'New epic',
        'aria-label': 'New epic',
      });
    });

    it('does not render New epic button when canCreateEpic is false', () => {
      createComponent({
        canCreateEpic: false,
        isEpicBoard: true,
      });

      expect(wrapper.findComponent(GlButtonGroup).exists()).toBe(false);
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
    describe('weightFeatureAvailable is true', () => {
      it.each`
        isEpicBoard | totalWeight
        ${true}     | ${epicBoardListQueryResponse().data.epicBoardList.metadata.totalWeight}
        ${false}    | ${boardListQueryResponse().data.boardList.totalWeight}
      `('isEpicBoard is $isEpicBoard', async ({ isEpicBoard, totalWeight }) => {
        createComponent({
          weightFeatureAvailable: true,
          isEpicBoard,
        });

        await waitForPromises();

        const weightTooltip = wrapper.findComponent({ ref: 'weightTooltip' });

        expect(weightTooltip.exists()).toBe(true);
        expect(weightTooltip.text()).toContain(totalWeight.toString());
      });
    });

    it('weightFeatureAvailable is false', () => {
      createComponent();

      expect(wrapper.findComponent({ ref: 'weightTooltip' }).exists()).toBe(false);
    });
  });
});
