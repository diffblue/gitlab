import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import createMockApollo from 'helpers/mock_apollo_helper';

import ToggleEpicsSwimlanes from 'ee/boards/components/toggle_epics_swimlanes.vue';
import IssueBoardFilteredSearch from 'ee/boards/components/issue_board_filtered_search.vue';
import EpicBoardFilteredSearch from 'ee/boards/components/epic_filtered_search.vue';
import ToggleLabels from 'ee/boards/components/toggle_labels.vue';

import BoardTopBar from '~/boards/components/board_top_bar.vue';
import BoardsSelector from '~/boards/components/boards_selector.vue';
import ConfigToggle from '~/boards/components/config_toggle.vue';
import NewBoardButton from '~/boards/components/new_board_button.vue';
import ToggleFocus from '~/boards/components/toggle_focus.vue';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';

import groupBoardQuery from '~/boards/graphql/group_board.query.graphql';
import projectBoardQuery from '~/boards/graphql/project_board.query.graphql';
import { mockProjectBoardResponse, mockGroupBoardResponse } from 'jest/boards/mock_data';
import epicBoardQuery from 'ee_component/boards/graphql/epic_board.query.graphql';
import { mockEpicBoardResponse } from '../mock_data';

Vue.use(VueApollo);
Vue.use(Vuex);

describe('BoardTopBar', () => {
  let wrapper;
  let mockApollo;

  const createStore = () => {
    return new Vuex.Store({
      state: {},
    });
  };

  const projectBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockProjectBoardResponse);
  const groupBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupBoardResponse);
  const epicBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockEpicBoardResponse);

  const createComponent = ({ provide = {} } = {}) => {
    const store = createStore();
    mockApollo = createMockApollo([
      [projectBoardQuery, projectBoardQueryHandlerSuccess],
      [groupBoardQuery, groupBoardQueryHandlerSuccess],
      [epicBoardQuery, epicBoardQueryHandlerSuccess],
    ]);

    wrapper = shallowMount(BoardTopBar, {
      store,
      apolloProvider: mockApollo,
      propsData: {
        boardId: 'gid://gitlab/Board/1',
        isSwimlanesOn: false,
      },
      provide: {
        swimlanesFeatureAvailable: false,
        canAdminList: false,
        isSignedIn: false,
        fullPath: 'gitlab-org',
        boardType: 'group',
        releasesFetchPath: '/releases',
        epicFeatureAvailable: true,
        iterationFeatureAvailable: true,
        healthStatusFeatureAvailable: true,
        isIssueBoard: true,
        isEpicBoard: false,
        isGroupBoard: true,
        isApolloBoard: false,
        ...provide,
      },
      stubs: { IssueBoardFilteredSearch, EpicBoardFilteredSearch, ToggleLabels },
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  describe('base template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders BoardsSelector component', () => {
      expect(wrapper.findComponent(BoardsSelector).exists()).toBe(true);
    });

    it('renders NewBoardButton component', () => {
      expect(wrapper.findComponent(NewBoardButton).exists()).toBe(true);
    });

    it('renders ConfigToggle component', () => {
      expect(wrapper.findComponent(ConfigToggle).exists()).toBe(true);
    });

    it('renders ToggleFocus component', () => {
      expect(wrapper.findComponent(ToggleFocus).exists()).toBe(true);
    });

    it('renders ToggleLabels component', () => {
      expect(wrapper.findComponent(ToggleLabels).exists()).toBe(true);
    });

    it('does not render ToggleEpicsSwimlanes component', () => {
      expect(wrapper.findComponent(ToggleEpicsSwimlanes).exists()).toBe(false);
    });
  });

  describe('filter bar', () => {
    it.each`
      isIssueBoard | filterBarComponent          | filterBarName                 | otherFilterBar
      ${true}      | ${IssueBoardFilteredSearch} | ${'IssueBoardFilteredSearch'} | ${EpicBoardFilteredSearch}
      ${false}     | ${EpicBoardFilteredSearch}  | ${'EpicBoardFilteredSearch'}  | ${IssueBoardFilteredSearch}
    `(
      'renders $filterBarName when isIssueBoard is $isIssueBoard',
      async ({ isIssueBoard, filterBarComponent, otherFilterBar }) => {
        createComponent({ provide: { isIssueBoard } });

        await nextTick();

        expect(wrapper.findComponent(filterBarComponent).exists()).toBe(true);
        expect(wrapper.findComponent(otherFilterBar).exists()).toBe(false);
      },
    );
  });

  describe('when user is logged in and swimlanes are available', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          swimlanesFeatureAvailable: true,
          isSignedIn: true,
        },
      });
    });

    it('renders ToggleEpicsSwimlanes component', () => {
      expect(wrapper.findComponent(ToggleEpicsSwimlanes).exists()).toBe(true);
    });
  });

  describe('Apollo boards', () => {
    it.each`
      boardType            | isEpicBoard | queryHandler                       | notCalledHandler
      ${WORKSPACE_GROUP}   | ${false}    | ${groupBoardQueryHandlerSuccess}   | ${projectBoardQueryHandlerSuccess}
      ${WORKSPACE_PROJECT} | ${false}    | ${projectBoardQueryHandlerSuccess} | ${groupBoardQueryHandlerSuccess}
      ${WORKSPACE_GROUP}   | ${true}     | ${epicBoardQueryHandlerSuccess}    | ${groupBoardQueryHandlerSuccess}
    `(
      'fetches $boardType boards when isEpicBoard is $isEpicBoard',
      async ({ boardType, isEpicBoard, queryHandler, notCalledHandler }) => {
        createComponent({
          provide: {
            boardType,
            isProjectBoard: boardType === WORKSPACE_PROJECT,
            isGroupBoard: boardType === WORKSPACE_GROUP,
            isEpicBoard,
            isApolloBoard: true,
          },
        });

        await nextTick();

        expect(queryHandler).toHaveBeenCalled();
        expect(notCalledHandler).not.toHaveBeenCalled();
      },
    );
  });
});
