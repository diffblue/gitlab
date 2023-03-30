import Vue, { nextTick } from 'vue';
import VirtualList from 'vue-virtual-scroll-list';
import Draggable from 'vuedraggable';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as BoardUtils from 'ee/boards/boards_util';
import EpicLane from 'ee/boards/components/epic_lane.vue';
import EpicsSwimlanes from 'ee/boards/components/epics_swimlanes.vue';
import IssueLaneList from 'ee/boards/components/issues_lane_list.vue';
import SwimlanesLoadingSkeleton from 'ee/boards/components/swimlanes_loading_skeleton.vue';
import { EPIC_LANE_BASE_HEIGHT } from 'ee/boards/constants';
import getters from 'ee/boards/stores/getters';
import epicsSwimlanesQuery from 'ee/boards/graphql/epics_swimlanes.query.graphql';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockLists,
  mockEpics,
  mockIssuesByListId,
  issues,
  mockEpicSwimlanesResponse,
} from '../mock_data';

Vue.use(VueApollo);
Vue.use(Vuex);
jest.mock('ee/boards/boards_util');

describe('EpicsSwimlanes', () => {
  let wrapper;
  let mockApollo;
  const bufferSize = 100;

  const findDraggable = () => wrapper.findComponent(Draggable);
  const findLoadMoreEpicsButton = () => wrapper.findByTestId('load-more-epics');
  const findUnassignedLaneList = () => wrapper.findComponent(IssueLaneList);
  const findLaneUnassignedIssues = () => wrapper.findByTestId('board-lane-unassigned-issues-title');
  const findToggleUnassignedLaneButton = () => wrapper.findByTestId('unassigned-lane-toggle');
  const findLoadMoreIssuesButton = () => wrapper.findByTestId('board-lane-load-more-issues-button');

  const fetchItemsForListSpy = jest.fn();
  const fetchIssuesForEpicSpy = jest.fn();
  const fetchEpicsSwimlanesSpy = jest.fn();

  const createStore = ({
    epicLanesFetchInProgress = false,
    listItemsFetchInProgress = false,
    epicLanesFetchMoreInProgress = false,
    hasMoreEpics = false,
  } = {}) => {
    return new Vuex.Store({
      state: {
        epics: mockEpics,
        boardItemsByListId: mockIssuesByListId,
        boardItems: issues,
        pageInfoByListId: {
          'gid://gitlab/List/1': {},
          'gid://gitlab/List/2': {},
        },
        epicsSwimlanesFetchInProgress: {
          epicLanesFetchInProgress,
          listItemsFetchInProgress,
          epicLanesFetchMoreInProgress,
        },
        hasMoreEpics,
        filterParams: {},
      },
      getters,
      actions: {
        fetchItemsForList: fetchItemsForListSpy,
        fetchIssuesForEpic: fetchIssuesForEpicSpy,
        fetchEpicsSwimlanes: fetchEpicsSwimlanesSpy,
      },
    });
  };

  const epicsSwimlanesQueryHandlerSuccess = jest.fn().mockResolvedValue(mockEpicSwimlanesResponse);

  const createComponent = ({
    canAdminList = false,
    epicLanesFetchInProgress = false,
    listItemsFetchInProgress = false,
    hasMoreEpics = false,
    isApolloBoard = false,
  } = {}) => {
    const store = createStore({ epicLanesFetchInProgress, listItemsFetchInProgress, hasMoreEpics });
    mockApollo = createMockApollo([[epicsSwimlanesQuery, epicsSwimlanesQueryHandlerSuccess]]);
    const defaultProps = {
      lists: mockLists,
      boardId: 'gid://gitlab/Board/1',
    };

    wrapper = shallowMountExtended(EpicsSwimlanes, {
      propsData: { ...defaultProps, canAdminList, filters: {} },
      apolloProvider: mockApollo,
      store,
      provide: {
        fullPath: 'gitlab-org',
        boardType: 'group',
        disabled: false,
        isApolloBoard,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(BoardUtils, 'calculateSwimlanesBufferSize').mockReturnValue(bufferSize);
  });

  it('calls fetchIssuesForEpic on mounted', () => {
    createComponent();
    expect(fetchIssuesForEpicSpy).toHaveBeenCalled();
  });

  describe('computed', () => {
    describe('treeRootWrapper', () => {
      describe('when canAdminList prop is true', () => {
        beforeEach(() => {
          createComponent({ canAdminList: true });
        });

        it('should return Draggable reference when canAdminList prop is true', () => {
          expect(findDraggable().exists()).toBe(true);
        });
      });

      describe('when canAdminList prop is false', () => {
        beforeEach(() => {
          createComponent();
        });

        it('should not return Draggable reference when canAdminList prop is false', () => {
          expect(findDraggable().exists()).toBe(false);
        });
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays BoardListHeader components for lists', () => {
      expect(wrapper.findAllComponents(BoardListHeader)).toHaveLength(4);
    });

    it('does not display IssueLaneList component by default', () => {
      expect(findUnassignedLaneList().exists()).toBe(false);
    });

    it('renders virtual-list', () => {
      const virtualList = wrapper.findComponent(VirtualList);
      const scrollableContainer = wrapper.findComponent({ ref: 'scrollableContainer' }).element;

      expect(BoardUtils.calculateSwimlanesBufferSize).toHaveBeenCalledWith(
        wrapper.element.offsetTop,
      );
      expect(virtualList.props()).toMatchObject({
        remain: bufferSize,
        bench: bufferSize,
        item: EpicLane,
        size: EPIC_LANE_BASE_HEIGHT,
        itemcount: mockEpics.length,
        itemprops: expect.any(Function),
      });

      expect(virtualList.props().scrollelement).toBe(scrollableContainer);
    });

    it('does not display load more epics button if there are no more epics', () => {
      expect(findLoadMoreEpicsButton().exists()).toBe(false);
    });

    it('displays IssueLaneList component when toggling unassigned issues lane', async () => {
      expect(findLaneUnassignedIssues().classes()).not.toContain('board-epic-lane-shadow');
      findToggleUnassignedLaneButton().vm.$emit('click');

      await nextTick();

      expect(findLaneUnassignedIssues().classes()).toContain('board-epic-lane-shadow');
      expect(findUnassignedLaneList().exists()).toBe(true);
    });

    it('makes non preset lists draggable', () => {
      expect(wrapper.findAll('[data-testid="board-header-container"]').at(1).classes()).toContain(
        'is-draggable',
      );
    });

    it('does not make preset lists draggable', () => {
      expect(
        wrapper.findAll('[data-testid="board-header-container"]').at(0).classes(),
      ).not.toContain('is-draggable');
    });
  });

  describe('load more epics', () => {
    beforeEach(() => {
      createComponent({ hasMoreEpics: true });
    });

    it('displays load more epics button if there are more epics', () => {
      expect(findLoadMoreEpicsButton().exists()).toBe(true);
    });

    it('calls fetchEpicsSwimlanes action when loading more epics', async () => {
      findLoadMoreEpicsButton().vm.$emit('click');

      await nextTick();

      expect(fetchEpicsSwimlanesSpy).toHaveBeenCalled();
    });
  });

  describe('Loading skeleton', () => {
    it.each`
      epicLanesFetchInProgress | listItemsFetchInProgress | expected
      ${true}                  | ${true}                  | ${true}
      ${false}                 | ${true}                  | ${true}
      ${true}                  | ${false}                 | ${true}
      ${false}                 | ${false}                 | ${false}
    `(
      'loading is $expected when epicLanesFetchInProgress is $epicLanesFetchInProgress and listItemsFetchInProgress is $listItemsFetchInProgress',
      ({ epicLanesFetchInProgress, listItemsFetchInProgress, expected }) => {
        createComponent({ epicLanesFetchInProgress, listItemsFetchInProgress });

        expect(wrapper.findComponent(SwimlanesLoadingSkeleton).exists()).toBe(expected);
      },
    );
  });

  describe('Apollo boards', () => {
    beforeEach(async () => {
      createComponent({ isApolloBoard: true });
      await waitForPromises();
    });

    it('fetches epics swimlanes', () => {
      expect(epicsSwimlanesQueryHandlerSuccess).toHaveBeenCalled();
    });

    describe('unassigned issues lane', () => {
      it('load more issues button does not display when all issues are loaded', async () => {
        expect(findUnassignedLaneList().exists()).toBe(false);
        expect(findLaneUnassignedIssues().exists()).toBe(true);

        findToggleUnassignedLaneButton().vm.$emit('click');

        await nextTick();

        expect(findUnassignedLaneList().exists()).toBe(true);
        expect(findLoadMoreIssuesButton().exists()).toBe(false);
      });

      it('load more issues button displays when there are more issues to load', async () => {
        findToggleUnassignedLaneButton().vm.$emit('click');
        await nextTick();

        wrapper
          .findComponent(IssueLaneList)
          .vm.$emit('updatePageInfo', { hasNextPage: true, endCursor: 'xyz' }, mockLists[0].id);

        await nextTick();

        expect(findLoadMoreIssuesButton().exists()).toBe(true);
      });
    });
  });
});
