import { GlDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import BoardsSelector from 'ee/boards/components/boards_selector.vue';
import { BoardType } from '~/boards/constants';
import epicBoardQuery from 'ee/boards/graphql/epic_board.query.graphql';
import epicBoardsQuery from 'ee/boards/graphql/epic_boards.query.graphql';
import groupBoardQuery from '~/boards/graphql/group_board.query.graphql';
import projectBoardQuery from '~/boards/graphql/project_board.query.graphql';
import groupBoardsQuery from '~/boards/graphql/group_boards.query.graphql';
import projectBoardsQuery from '~/boards/graphql/project_boards.query.graphql';
import defaultStore from '~/boards/stores';
import { TEST_HOST } from 'spec/test_constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import {
  mockGroupBoardResponse,
  mockProjectBoardResponse,
  mockGroupAllBoardsResponse,
  mockProjectAllBoardsResponse,
} from 'jest/boards/mock_data';
import { mockEpicBoardResponse, mockEpicBoardsResponse } from '../mock_data';

const throttleDuration = 1;

Vue.use(VueApollo);

describe('BoardsSelector', () => {
  let wrapper;
  let fakeApollo;
  let store;

  const createStore = ({
    isGroupBoard = false,
    isProjectBoard = false,
    isEpicBoard = false,
  } = {}) => {
    store = new Vuex.Store({
      ...defaultStore,
      actions: {
        setError: jest.fn(),
      },
      getters: {
        isEpicBoard: () => isEpicBoard,
        isGroupBoard: () => isGroupBoard,
        isProjectBoard: () => isProjectBoard,
      },
      state: {
        boardType: isGroupBoard ? BoardType.group : BoardType.project,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);

  const projectBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockProjectBoardResponse);
  const groupBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupBoardResponse);
  const epicBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockEpicBoardResponse);

  const projectBoardsQueryHandlerSuccess = jest
    .fn()
    .mockResolvedValue(mockProjectAllBoardsResponse);
  const groupBoardsQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupAllBoardsResponse);
  const epicBoardsQueryHandlerSuccess = jest.fn().mockResolvedValue(mockEpicBoardsResponse);

  const createComponent = () => {
    fakeApollo = createMockApollo([
      [projectBoardQuery, projectBoardQueryHandlerSuccess],
      [groupBoardQuery, groupBoardQueryHandlerSuccess],
      [epicBoardQuery, epicBoardQueryHandlerSuccess],
      [projectBoardsQuery, projectBoardsQueryHandlerSuccess],
      [groupBoardsQuery, groupBoardsQueryHandlerSuccess],
      [epicBoardsQuery, epicBoardsQueryHandlerSuccess],
    ]);

    wrapper = mount(BoardsSelector, {
      store,
      apolloProvider: fakeApollo,
      propsData: {
        throttleDuration,
        boardBaseUrl: `${TEST_HOST}/board/base/url`,
        hasMissingBoards: false,
        canAdminBoard: true,
        multipleIssueBoardsAvailable: true,
        scopedIssueBoardFeatureEnabled: true,
        weights: [],
      },
      attachTo: document.body,
      provide: {
        fullPath: '',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
    store = null;
  });

  describe('fetching all boards', () => {
    beforeEach(() => {
      it.each`
        boardType            | isEpicBoard | queryHandler                        | notCalledHandler
        ${BoardType.group}   | ${false}    | ${groupBoardsQueryHandlerSuccess}   | ${projectBoardsQueryHandlerSuccess}
        ${BoardType.project} | ${false}    | ${projectBoardsQueryHandlerSuccess} | ${groupBoardsQueryHandlerSuccess}
        ${BoardType.group}   | ${true}     | ${epicBoardsQueryHandlerSuccess}    | ${groupBoardsQueryHandlerSuccess}
      `(
        'fetches $boardType boards when isEpicBoard is $isEpicBoard',
        async ({ boardType, isEpicBoard, queryHandler, notCalledHandler }) => {
          createStore({
            isProjectBoard: boardType === BoardType.project,
            isGroupBoard: boardType === BoardType.group,
            isEpicBoard,
          });
          createComponent();

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

  describe('fetching current board', () => {
    it.each`
      boardType            | isEpicBoard | queryHandler                       | notCalledHandler
      ${BoardType.group}   | ${false}    | ${groupBoardQueryHandlerSuccess}   | ${projectBoardQueryHandlerSuccess}
      ${BoardType.project} | ${false}    | ${projectBoardQueryHandlerSuccess} | ${groupBoardQueryHandlerSuccess}
      ${BoardType.group}   | ${true}     | ${epicBoardQueryHandlerSuccess}    | ${groupBoardQueryHandlerSuccess}
    `(
      'fetches $boardType board when isEpicBoard is $isEpicBoard',
      async ({ boardType, isEpicBoard, queryHandler, notCalledHandler }) => {
        createStore({
          isProjectBoard: boardType === BoardType.project,
          isGroupBoard: boardType === BoardType.group,
          isEpicBoard,
        });
        createComponent();

        await nextTick();

        expect(queryHandler).toHaveBeenCalled();
        expect(notCalledHandler).not.toHaveBeenCalled();
      },
    );
  });
});
