import { GlDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import BoardsSelector from 'ee/boards/components/boards_selector.vue';
import { BoardType } from '~/boards/constants';
import epicBoardsQuery from 'ee/boards/graphql/epic_boards.query.graphql';
import groupBoardsQuery from '~/boards/graphql/group_boards.query.graphql';
import projectBoardsQuery from '~/boards/graphql/project_boards.query.graphql';
import groupRecentBoardsQuery from '~/boards/graphql/group_recent_boards.query.graphql';
import projectRecentBoardsQuery from '~/boards/graphql/project_recent_boards.query.graphql';
import { TEST_HOST } from 'spec/test_constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  mockBoard,
  mockGroupAllBoardsResponse,
  mockProjectAllBoardsResponse,
  mockProjectRecentBoardsResponse,
  mockGroupRecentBoardsResponse,
} from 'jest/boards/mock_data';
import { mockEpicBoardsResponse } from '../mock_data';

const throttleDuration = 1;

Vue.use(VueApollo);
Vue.use(Vuex);

describe('BoardsSelector', () => {
  let wrapper;
  let fakeApollo;
  let store;

  const createStore = () => {
    store = new Vuex.Store({
      actions: {
        setError: jest.fn(),
        setBoardConfig: jest.fn(),
      },
      state: {
        board: mockBoard,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);

  const projectBoardsQueryHandlerSuccess = jest
    .fn()
    .mockResolvedValue(mockProjectAllBoardsResponse);
  const groupBoardsQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupAllBoardsResponse);
  const epicBoardsQueryHandlerSuccess = jest.fn().mockResolvedValue(mockEpicBoardsResponse);

  const projectRecentBoardsQueryHandlerSuccess = jest
    .fn()
    .mockResolvedValue(mockProjectRecentBoardsResponse);
  const groupRecentBoardsQueryHandlerSuccess = jest
    .fn()
    .mockResolvedValue(mockGroupRecentBoardsResponse);

  const createComponent = ({
    isEpicBoard = false,
    isGroupBoard = false,
    isProjectBoard = false,
  }) => {
    fakeApollo = createMockApollo([
      [projectBoardsQuery, projectBoardsQueryHandlerSuccess],
      [groupBoardsQuery, groupBoardsQueryHandlerSuccess],
      [epicBoardsQuery, epicBoardsQueryHandlerSuccess],
      [projectRecentBoardsQuery, projectRecentBoardsQueryHandlerSuccess],
      [groupRecentBoardsQuery, groupRecentBoardsQueryHandlerSuccess],
    ]);

    wrapper = mount(BoardsSelector, {
      store,
      apolloProvider: fakeApollo,
      propsData: {
        throttleDuration,
      },
      attachTo: document.body,
      provide: {
        fullPath: '',
        boardBaseUrl: `${TEST_HOST}/board/base/url`,
        hasMissingBoards: false,
        canAdminBoard: true,
        multipleIssueBoardsAvailable: true,
        scopedIssueBoardFeatureEnabled: true,
        weights: [],
        isEpicBoard,
        boardType: isGroupBoard ? BoardType.group : BoardType.project,
        isGroupBoard,
        isProjectBoard,
        isApolloBoard: false,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
    store = null;
  });

  describe('fetching all boards', () => {
    it.each`
      boardType            | isEpicBoard | queryHandler                        | notCalledHandler
      ${BoardType.group}   | ${false}    | ${groupBoardsQueryHandlerSuccess}   | ${projectBoardsQueryHandlerSuccess}
      ${BoardType.project} | ${false}    | ${projectBoardsQueryHandlerSuccess} | ${groupBoardsQueryHandlerSuccess}
      ${BoardType.group}   | ${true}     | ${epicBoardsQueryHandlerSuccess}    | ${groupBoardsQueryHandlerSuccess}
    `(
      'fetches $boardType boards when isEpicBoard is $isEpicBoard',
      async ({ boardType, isEpicBoard, queryHandler, notCalledHandler }) => {
        createStore();
        createComponent({
          isEpicBoard,
          isProjectBoard: boardType === BoardType.project,
          isGroupBoard: boardType === BoardType.group,
        });

        await nextTick();

        // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
        findDropdown().vm.$emit('show');

        await nextTick();

        expect(queryHandler).toHaveBeenCalled();
        expect(notCalledHandler).not.toHaveBeenCalled();
      },
    );
  });
});
