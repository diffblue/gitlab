import { GlDropdown, GlLoadingIcon, GlDropdownSectionHeader } from '@gitlab/ui';
import { createLocalVue, mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import BoardsSelector from 'ee/boards/components/boards_selector.vue';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';

const throttleDuration = 1;

const localVue = createLocalVue();
localVue.use(Vuex);

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
  const boards = boardGenerator(20);
  const recentBoards = boardGenerator(5);

  const createStore = () => {
    return new Vuex.Store({
      getters: {
        isEpicBoard: () => false,
      },
    });
  };

  const getDropdownItems = () => wrapper.findAll('.js-dropdown-item');
  const getDropdownHeaders = () => wrapper.findAllComponents(GlDropdownSectionHeader);
  const getLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDropdown = () => wrapper.findComponent(GlDropdown);

  beforeEach(() => {
    mock = new MockAdapter(axios);
    const $apollo = {
      queries: {
        boards: {
          loading: false,
        },
      },
    };

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

    const store = createStore();

    wrapper = mount(BoardsSelector, {
      localVue,
      propsData: {
        throttleDuration,
        currentBoard: {
          id: 1,
          name: 'Development',
          milestone_id: null,
          weight: null,
          assignee_id: null,
          labels: [],
        },
        boardBaseUrl: `${TEST_HOST}/board/base/url`,
        hasMissingBoards: false,
        canAdminBoard: true,
        multipleIssueBoardsAvailable: true,
        scopedIssueBoardFeatureEnabled: true,
        weights: [],
      },
      mocks: { $apollo },
      attachTo: document.body,
      provide: {
        fullPath: '',
        recentBoardsEndpoint: `${TEST_HOST}/recent`,
      },
      store,
    });

    wrapper.vm.$apollo.addSmartQuery = jest.fn((_, options) => {
      wrapper.setData({
        [options.loadingKey]: true,
      });
    });

    mock.onGet(`${TEST_HOST}/recent`).replyOnce(200, recentBoards);

    // Emits gl-dropdown show event to simulate the dropdown is opened at initialization time
    findDropdown().vm.$emit('show');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mock.restore();
  });

  describe('loading', () => {
    // we are testing loading state, so don't resolve responses until after the tests
    afterEach(async () => {
      await Promise.all([allBoardsResponse, recentBoardsResponse]);
      return nextTick();
    });

    it('shows loading spinner', () => {
      expect(getDropdownHeaders()).toHaveLength(0);
      expect(getDropdownItems()).toHaveLength(0);
      expect(getLoadingIcon().exists()).toBe(true);
    });
  });

  describe('loaded', () => {
    beforeEach(async () => {
      await wrapper.setData({
        loadingBoards: false,
      });
      // NOTE: Due to timing issues, this `return` of `Promise.all` is required because
      // `app/assets/javascripts/boards/components/boards_selector.vue` does a `$nextTick()` in
      // loadRecentBoards. For some unknown reason it doesn't work with `await`, the `return`
      // is required.
      return Promise.all([allBoardsResponse, recentBoardsResponse]).then(() => nextTick());
    });

    it('hides loading spinner', async () => {
      await wrapper.vm.$nextTick();
      expect(getLoadingIcon().exists()).toBe(false);
    });
  });
});
