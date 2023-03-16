import { GlButton, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import createMockApollo from 'helpers/mock_apollo_helper';
import listsIssuesQuery from '~/boards/graphql/lists_issues.query.graphql';
import EpicLane from 'ee/boards/components/epic_lane.vue';
import IssuesLaneList from 'ee/boards/components/issues_lane_list.vue';
import getters from 'ee/boards/stores/getters';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  mockEpic,
  mockLists,
  mockIssuesByListId,
  issues,
  mockGroupIssuesResponse,
} from '../mock_data';

Vue.use(VueApollo);
Vue.use(Vuex);

describe('EpicLane', () => {
  let wrapper;
  let mockApollo;

  const updateBoardEpicUserPreferencesSpy = jest.fn();
  const fetchIssuesForEpicSpy = jest.fn();

  const findChevronButton = () => wrapper.findComponent(GlButton);
  const findEpicLane = () => wrapper.findByTestId('board-epic-lane');
  const findEpicLaneIssueCount = () => wrapper.findByTestId('epic-lane-issue-count');

  const createStore = ({ boardItemsByListId = mockIssuesByListId, isLoading = false }) => {
    return new Vuex.Store({
      actions: {
        updateBoardEpicUserPreferences: updateBoardEpicUserPreferencesSpy,
        fetchIssuesForEpic: fetchIssuesForEpicSpy,
      },
      state: {
        boardItemsByListId,
        boardItems: issues,
        epicsFlags: {
          [mockEpic.id]: {
            isLoading,
          },
        },
      },
      getters,
    });
  };

  const listIssuesQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupIssuesResponse);

  const createComponent = ({
    props = {},
    boardItemsByListId = mockIssuesByListId,
    isLoading = false,
    isApolloBoard = false,
  } = {}) => {
    const store = createStore({ boardItemsByListId, isLoading });
    mockApollo = createMockApollo([[listsIssuesQuery, listIssuesQueryHandlerSuccess]]);

    const defaultProps = {
      epic: mockEpic,
      lists: mockLists,
      boardId: 'gid://gitlab/Board/1',
      filterParams: {},
    };

    wrapper = shallowMountExtended(EpicLane, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      apolloProvider: mockApollo,
      store,
      provide: {
        fullPath: 'gitlab-org',
        boardType: 'group',
        isApolloBoard,
      },
    });
  };

  describe('mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('calls fetchIssuesForEpic action on mount', () => {
      expect(fetchIssuesForEpicSpy).toHaveBeenCalledWith(expect.any(Object), mockEpic.id);
    });
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays count of issues in epic which belong to board', () => {
      expect(findEpicLaneIssueCount().text()).toContain('2');
    });

    it('displays 1 icon', () => {
      expect(wrapper.findAllComponents(GlIcon)).toHaveLength(1);
    });

    it('displays epic title', () => {
      expect(wrapper.text()).toContain(mockEpic.title);
    });

    it('renders one IssuesLaneList component per list passed in props', () => {
      expect(wrapper.findAllComponents(IssuesLaneList)).toHaveLength(wrapper.props('lists').length);
    });

    it('hides issues when collapsing', async () => {
      expect(wrapper.findAllComponents(IssuesLaneList)).toHaveLength(wrapper.props('lists').length);
      expect(wrapper.vm.isCollapsed).toBe(false);

      findChevronButton().vm.$emit('click');

      await nextTick();
      expect(wrapper.findAllComponents(IssuesLaneList)).toHaveLength(0);
      expect(wrapper.vm.isCollapsed).toBe(true);
    });

    it('does not display loading icon when issues are not loading', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
    });

    it('displays loading icon and hides issues count when issues are loading', () => {
      createComponent({ isLoading: true });
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(findEpicLaneIssueCount().exists()).toBe(false);
    });

    it('invokes `updateBoardEpicUserPreferences` method on collapse', async () => {
      const collapsedValue = false;

      expect(wrapper.vm.isCollapsed).toBe(collapsedValue);
      expect(findEpicLane().classes()).toContain('board-epic-lane-shadow');

      findChevronButton().vm.$emit('click');

      await nextTick();
      expect(updateBoardEpicUserPreferencesSpy).toHaveBeenCalled();

      const payload = updateBoardEpicUserPreferencesSpy.mock.calls[0][1];

      expect(payload).toEqual({
        collapsed: !collapsedValue,
        epicId: mockEpic.id,
      });
      expect(wrapper.vm.isCollapsed).toBe(true);
      expect(findEpicLane().classes()).not.toContain('board-epic-lane-shadow');
    });

    it('does not render when issuesCount is 0', () => {
      createComponent({ boardItemsByListId: {} });
      expect(findEpicLane().exists()).toBe(false);
    });
  });

  describe('Apollo boards', () => {
    beforeEach(() => {
      createComponent({ isApolloBoard: true });
    });

    it('fetches list issues', () => {
      expect(listIssuesQueryHandlerSuccess).toHaveBeenCalled();
    });
  });
});
