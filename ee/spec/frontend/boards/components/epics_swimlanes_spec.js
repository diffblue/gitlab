import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VirtualList from 'vue-virtual-scroll-list';
import Draggable from 'vuedraggable';
import Vuex from 'vuex';
import * as BoardUtils from 'ee/boards/boards_util';
import EpicLane from 'ee/boards/components/epic_lane.vue';
import EpicsSwimlanes from 'ee/boards/components/epics_swimlanes.vue';
import IssueLaneList from 'ee/boards/components/issues_lane_list.vue';
import SwimlanesLoadingSkeleton from 'ee/boards/components/swimlanes_loading_skeleton.vue';
import { EPIC_LANE_BASE_HEIGHT } from 'ee/boards/constants';
import getters from 'ee/boards/stores/getters';
import BoardListHeader from 'ee_else_ce/boards/components/board_list_header.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockLists, mockEpics, mockIssuesByListId, issues } from '../mock_data';

Vue.use(Vuex);
jest.mock('ee/boards/boards_util');

describe('EpicsSwimlanes', () => {
  let wrapper;
  const bufferSize = 100;

  const findDraggable = () => wrapper.findComponent(Draggable);
  const findLoadMoreEpicsButton = () => wrapper.findByTestId('load-more-epics');

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
      },
      getters,
      actions: {
        fetchItemsForList: fetchItemsForListSpy,
        fetchIssuesForEpic: fetchIssuesForEpicSpy,
        fetchEpicsSwimlanes: fetchEpicsSwimlanesSpy,
      },
    });
  };

  const createComponent = ({
    canAdminList = false,
    epicLanesFetchInProgress = false,
    listItemsFetchInProgress = false,
    hasMoreEpics = false,
  } = {}) => {
    const store = createStore({ epicLanesFetchInProgress, listItemsFetchInProgress, hasMoreEpics });
    const defaultProps = {
      lists: mockLists,
    };

    wrapper = extendedWrapper(
      shallowMount(EpicsSwimlanes, {
        propsData: { ...defaultProps, canAdminList },
        store,
        provide: {
          disabled: false,
        },
      }),
    );
  };

  beforeEach(() => {
    jest.spyOn(BoardUtils, 'calculateSwimlanesBufferSize').mockReturnValue(bufferSize);
  });

  afterEach(() => {
    wrapper.destroy();
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
      expect(wrapper.findComponent(IssueLaneList).exists()).toBe(false);
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
      wrapper.findByTestId('unassigned-lane-toggle').vm.$emit('click');

      await nextTick();
      expect(wrapper.findComponent(IssueLaneList).exists()).toBe(true);
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
});
