import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import BoardListHeader from 'ee/boards/components/board_list_header.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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

  const setFullBoardIssuesCountSpy = jest.fn();
  const mockClientToggleListCollapsedResolver = jest.fn();
  const mockClientToggleEpicListCollapsedResolver = jest.fn();

  afterEach(() => {
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
    currentUserId = 1,
    state = { activeId: inactiveId },
    isEpicBoard = false,
    issuableType = 'issue',
    injectedProps = {},
  } = {}) => {
    const boardId = 'gid://gitlab/Board/1';

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

    fakeApollo = createMockApollo(
      [
        [listQuery, listQueryHandler],
        [epicListQuery, jest.fn().mockResolvedValue(epicBoardListQueryResponse())],
      ],
      {
        Mutation: {
          clientToggleListCollapsed: mockClientToggleListCollapsedResolver,
          clientToggleEpicListCollapsed: mockClientToggleEpicListCollapsedResolver,
        },
      },
    );

    store = new Vuex.Store({
      state,
      actions: {
        setFullBoardIssuesCount: setFullBoardIssuesCountSpy,
        setActiveId: jest.fn(),
      },
    });

    wrapper = shallowMountExtended(BoardListHeader, {
      apolloProvider: fakeApollo,
      store,
      propsData: {
        list: listMock,
        filterParams: {},
        isSwimlanesHeader,
        boardId,
      },
      provide: {
        weightFeatureAvailable,
        currentUserId,
        canCreateEpic,
        isEpicBoard,
        disabled: false,
        issuableType,
        ...injectedProps,
      },
      stubs: {
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
    });

    wrapper.vm.$refs.headerListActions = { close: jest.fn() };
  };

  const newEpicText = 'Create new epic';
  const listSettingsText = 'Edit list settings';
  const newEpicBtnTestId = 'newEpicBtn';
  const listSettingsTestId = 'settingsBtn';

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findNewEpicButton = () => wrapper.findByTestId(newEpicBtnTestId);
  const findSettingsButton = () => wrapper.findByTestId(listSettingsTestId);
  const findCaret = () => wrapper.findByTestId('board-title-caret');

  afterEach(() => {
    localStorage.clear();
  });

  describe('New epic button', () => {
    beforeEach(() => {
      jest.spyOn(boardsEventHub, '$emit');
      createComponent({ isEpicBoard: true, issuableType: 'epic' });
    });

    it('renders Create new epic button', () => {
      expect(findDropdown().exists()).toBe(true);

      expect(findNewEpicButton().exists()).toBe(true);

      expect(findNewEpicButton().attributes()).toMatchObject({
        'data-testid': newEpicBtnTestId,
        title: newEpicText,
        'aria-label': newEpicText,
      });
    });

    it('does not render dropdown and New epic button when canCreateEpic is false', () => {
      createComponent({
        canCreateEpic: false,
        isEpicBoard: true,
        issuableType: 'epic',
      });

      expect(findDropdown().exists()).toBe(false);
    });

    it('emits `toggle-epic-form` event on Sidebar eventHub when clicked', () => {
      expect(boardsEventHub.$emit).not.toHaveBeenCalled();

      findNewEpicButton().trigger('click');

      expect(boardsEventHub.$emit).toHaveBeenCalledWith(`toggle-epic-form-${mockList.id}`);
      expect(boardsEventHub.$emit).toHaveBeenCalledTimes(1);
    });
  });

  describe('Settings Button', () => {
    const hasSettings = [ListType.assignee, ListType.milestone, ListType.iteration, ListType.label];

    it.each(hasSettings)('does render for List Type `%s`', (listType) => {
      createComponent({ listType });

      expect(findSettingsButton().attributes()).toMatchObject({
        'data-testid': listSettingsTestId,
        title: listSettingsText,
        'aria-label': listSettingsText,
      });
    });

    it('does not render for List Type `backlog`', () => {
      const listType = ListType.backlog;

      createComponent({ listType });

      expect(findSettingsButton().exists()).toBe(false);
    });

    it('does not render dropdown for List Type `closed`', () => {
      const listType = ListType.closed;
      createComponent({ listType });

      expect(findDropdown().exists()).toBe(false);
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

  describe('setFullBoardIssuesCount action', () => {
    const listId = boardListQueryResponse().data.boardList.id;
    const count = boardListQueryResponse().data.boardList.issuesCount;

    it('calls setFullBoardIssuesCount when isEpicBoard is false', async () => {
      createComponent({ isEpicBoard: false });
      await waitForPromises();

      expect(setFullBoardIssuesCountSpy).toHaveBeenCalledWith(expect.any(Object), {
        listId,
        count,
      });
    });

    it('does not call setFullBoardIssuesCount when isEpicBoard is true', async () => {
      createComponent({ isEpicBoard: true, issuableType: 'epic' });
      await waitForPromises();

      expect(setFullBoardIssuesCountSpy).not.toHaveBeenCalled();
    });
  });

  describe('weightFeatureAvailable', () => {
    describe('weightFeatureAvailable is true', () => {
      it.each`
        isEpicBoard | issuableType | totalWeight
        ${true}     | ${'epic'}    | ${epicBoardListQueryResponse().data.epicBoardList.metadata.totalWeight}
        ${false}    | ${'issue'}   | ${boardListQueryResponse().data.boardList.totalWeight}
      `('isEpicBoard is $isEpicBoard', async ({ isEpicBoard, totalWeight, issuableType }) => {
        createComponent({
          weightFeatureAvailable: true,
          isEpicBoard,
          issuableType,
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

  describe('Apollo boards', () => {
    it.each`
      issuableType | isEpicBoard | queryHandler                                 | notCalledHandler
      ${'epic'}    | ${true}     | ${mockClientToggleEpicListCollapsedResolver} | ${mockClientToggleListCollapsedResolver}
      ${'issue'}   | ${false}    | ${mockClientToggleListCollapsedResolver}     | ${mockClientToggleEpicListCollapsedResolver}
    `(
      'sets $issuableType list collapsed state',
      async ({ issuableType, isEpicBoard, queryHandler, notCalledHandler }) => {
        createComponent({
          injectedProps: { isApolloBoard: true, issuableType, isEpicBoard },
        });

        await nextTick();
        findCaret().vm.$emit('click');
        await nextTick();

        expect(queryHandler).toHaveBeenCalledWith(
          {},
          {
            list: mockList,
            collapsed: true,
          },
          expect.anything(),
          expect.anything(),
        );
        expect(notCalledHandler).not.toHaveBeenCalled();
      },
    );
  });
});
