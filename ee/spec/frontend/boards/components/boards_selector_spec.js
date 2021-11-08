import { GlDropdown, GlLoadingIcon, GlDropdownSectionHeader } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import BoardsSelector from 'ee/boards/components/boards_selector.vue';
import { BoardType } from '~/boards/constants';
import epicBoardQuery from 'ee/boards/graphql/epic_board.query.graphql';
import groupBoardQuery from '~/boards/graphql/group_board.query.graphql';
import projectBoardQuery from '~/boards/graphql/project_board.query.graphql';
import defaultStore from '~/boards/stores';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockGroupBoardResponse, mockProjectBoardResponse } from 'jest/boards/mock_data';
import { mockEpicBoardResponse } from '../mock_data';

const throttleDuration = 1;

Vue.use(VueApollo);

function boardGenerator(n) {
  return new Array(n).fill().map((board, index) => {
    const id = `${index}`;
    const name = `board${id}`;

    return {
      id,
      name,
    };
  });
}

describe('BoardsSelector', () => {
  let wrapper;
  let allBoardsResponse;
  let recentBoardsResponse;
  let mock;
  let fakeApollo;
  let store;
  const boards = boardGenerator(20);
  const recentBoards = boardGenerator(5);

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

  const getDropdownItems = () => wrapper.findAll('.js-dropdown-item');
  const getDropdownHeaders = () => wrapper.findAllComponents(GlDropdownSectionHeader);
  const getLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDropdown = () => wrapper.findComponent(GlDropdown);

  const projectBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockProjectBoardResponse);
  const groupBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockGroupBoardResponse);
  const epicBoardQueryHandlerSuccess = jest.fn().mockResolvedValue(mockEpicBoardResponse);

  const createComponent = () => {
    fakeApollo = createMockApollo([
      [projectBoardQuery, projectBoardQueryHandlerSuccess],
      [groupBoardQuery, groupBoardQueryHandlerSuccess],
      [epicBoardQuery, epicBoardQueryHandlerSuccess],
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
        recentBoardsEndpoint: `${TEST_HOST}/recent`,
      },
    });

    wrapper.vm.$apollo.addSmartQuery = jest.fn((_, options) => {
      wrapper.setData({
        [options.loadingKey]: true,
      });
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    fakeApollo = null;
    store = null;
    mock.restore();
  });

  describe('fetching all board', () => {
    beforeEach(() => {
      mock = new MockAdapter(axios);

      allBoardsResponse = Promise.resolve({
        data: {
          group: {
            boards: {
              edges: boards.map((board) => ({ node: board })),
            },
          },
        },
      });
      recentBoardsResponse = Promise.resolve({
        data: recentBoards,
      });

      createStore();
      createComponent();

      mock.onGet(`${TEST_HOST}/recent`).replyOnce(200, recentBoards);
    });

    describe('loading', () => {
      beforeEach(async () => {
        // Wait for current board to be loaded
        await nextTick();

        // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
        findDropdown().vm.$emit('show');
      });

      // we are testing loading state, so don't resolve responses until after the tests
      afterEach(async () => {
        await Promise.all([allBoardsResponse, recentBoardsResponse]);
        await nextTick();
      });

      it('shows loading spinner', () => {
        expect(getDropdownHeaders()).toHaveLength(0);
        expect(getDropdownItems()).toHaveLength(0);
        expect(getLoadingIcon().exists()).toBe(true);
      });
    });

    describe('loaded', () => {
      beforeEach(async () => {
        // Wait for current board to be loaded
        await nextTick();

        // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
        findDropdown().vm.$emit('show');

        await wrapper.setData({
          loadingBoards: false,
          loadingRecentBoards: false,
        });
      });

      it('hides loading spinner', async () => {
        await nextTick();
        expect(getLoadingIcon().exists()).toBe(false);
      });
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
