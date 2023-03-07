import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/vue_shared/dashboards/store/actions';
import createStore from 'ee/vue_shared/dashboards/store/index';
import * as types from 'ee/vue_shared/dashboards/store/mutation_types';
import { mockHeaders, mockText, mockProjectData } from 'ee_jest/vue_shared/dashboards/mock_data';
import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

import clearState from '../helpers';

jest.mock('~/alert');

describe('actions', () => {
  const mockAddEndpoint = 'mock-add_endpoint';
  const mockListEndpoint = 'mock-list_endpoint';
  const mockResponse = { data: 'mock-data' };
  const mockProjects = mockProjectData(1);
  const [mockOneProject] = mockProjects;
  let store;
  let mockAxios;

  beforeEach(() => {
    store = createStore();
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    clearState(store);
    mockAxios.restore();
    actions.clearProjectsEtagPoll();
  });

  describe('addProjectsToDashboard', () => {
    it('posts selected project ids to project add endpoint', () => {
      store.state.projectEndpoints.add = mockAddEndpoint;
      store.state.selectedProjects = mockProjects;

      mockAxios.onPost(mockAddEndpoint).replyOnce(HTTP_STATUS_OK, mockResponse);

      return testAction(
        actions.addProjectsToDashboard,
        null,
        store.state,
        [],
        [
          {
            type: 'receiveAddProjectsToDashboardSuccess',
            payload: mockResponse,
          },
        ],
      );
    });

    it('calls addProjectsToDashboard error handler on error', () => {
      mockAxios.onPost(mockAddEndpoint).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return testAction(
        actions.addProjectsToDashboard,
        null,
        store.state,
        [],
        [{ type: 'receiveAddProjectsToDashboardError' }],
      );
    });
  });

  describe('toggleSelectedProject', () => {
    it(`adds a project to selectedProjects if it doesn't already exist in the list`, () => {
      return testAction(
        actions.toggleSelectedProject,
        mockOneProject,
        store.state,
        [
          {
            type: types.ADD_SELECTED_PROJECT,
            payload: mockOneProject,
          },
        ],
        [],
      );
    });

    it(`removes a project from selectedProjects if it already exist in the list`, () => {
      store.state.selectedProjects = mockProjects;

      return testAction(
        actions.toggleSelectedProject,
        mockOneProject,
        store.state,
        [
          {
            type: types.REMOVE_SELECTED_PROJECT,
            payload: mockOneProject,
          },
        ],
        [],
      );
    });
  });

  describe('receiveAddProjectsToDashboardSuccess', () => {
    it('fetches projects when new projects are added to the dashboard', () => {
      return testAction(
        actions.receiveAddProjectsToDashboardSuccess,
        {
          added: [1],
          invalid: [],
          duplicate: [],
        },
        store.state,
        [],
        [
          {
            type: 'forceProjectsRequest',
          },
        ],
      );
    });

    const errorMessage =
      'This dashboard is available for public projects, and private projects in groups with a Premium plan.';
    const selectProjects = (count) => {
      for (let i = 0; i < count; i += 1) {
        store.dispatch('toggleSelectedProject', {
          id: i,
          name: 'mock-name',
        });
      }
    };
    const addInvalidProjects = (invalid) =>
      store.dispatch('receiveAddProjectsToDashboardSuccess', {
        added: [],
        invalid,
        duplicate: [],
      });

    it('displays an error when user tries to add one invalid project to dashboard', () => {
      selectProjects(1);
      addInvalidProjects([0]);

      expect(createAlert).toHaveBeenCalledWith({
        message: `Unable to add mock-name. ${errorMessage}`,
      });
    });

    it('displays an error when user tries to add two invalid projects to dashboard', () => {
      selectProjects(2);
      addInvalidProjects([0, 1]);

      expect(createAlert).toHaveBeenCalledWith({
        message: `Unable to add mock-name and mock-name. ${errorMessage}`,
      });
    });

    it('displays an error when user tries to add more than two invalid projects to dashboard', () => {
      selectProjects(3);
      addInvalidProjects([0, 1, 2]);

      expect(createAlert).toHaveBeenCalledWith({
        message: `Unable to add mock-name, mock-name, and mock-name. ${errorMessage}`,
      });
    });
  });

  describe('receiveAddProjectsToDashboardError', () => {
    it('shows error message', () => {
      store.dispatch('receiveAddProjectsToDashboardError');

      expect(createAlert).toHaveBeenCalledWith({
        message: mockText.ADD_PROJECTS_ERROR,
      });
    });
  });

  describe('clearSearchResults', () => {
    it('clears all project search results', () => {
      store.state.projectSearchResults = mockProjects;

      return testAction(
        actions.clearSearchResults,
        null,
        store.state,
        [
          {
            type: types.CLEAR_SEARCH_RESULTS,
          },
        ],
        [],
      );
    });
  });

  describe('fetchProjects', () => {
    const testListEndpoint = ({ page }) => {
      store.state.projectEndpoints.list = mockListEndpoint;
      mockAxios
        .onGet(mockListEndpoint, {
          params: {
            page,
          },
        })
        .replyOnce(HTTP_STATUS_OK, { projects: mockProjects }, mockHeaders);

      return testAction(
        actions.fetchProjects,
        page,
        store.state,
        [
          {
            type: 'RECEIVE_PROJECTS_SUCCESS',
            payload: {
              headers: mockHeaders,
              projects: mockProjects,
            },
          },
        ],
        [{ type: 'requestProjects' }],
      );
    };

    it('calls project list endpoint', () => testListEndpoint({ page: null }));

    it('calls paginated project list endpoint', () => testListEndpoint({ page: 2 }));

    it('handles response errors', () => {
      store.state.projectEndpoints.list = mockListEndpoint;
      mockAxios.onGet(mockListEndpoint).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return testAction(
        actions.fetchProjects,
        null,
        store.state,
        [],
        [{ type: 'requestProjects' }, { type: 'receiveProjectsError' }],
      );
    });
  });

  describe('requestProjects', () => {
    it('toggles project loading state', () => {
      return testAction(
        actions.requestProjects,
        null,
        store.state,
        [{ type: types.REQUEST_PROJECTS }],
        [],
      );
    });
  });

  describe('receiveProjectsError', () => {
    it('clears projects and alerts user of error', () => {
      store.state.projects = mockProjects;

      testAction(
        actions.receiveProjectsError,
        null,
        store.state,
        [
          {
            type: types.RECEIVE_PROJECTS_ERROR,
          },
        ],
        [],
      );

      expect(createAlert).toHaveBeenCalledWith({
        message: mockText.RECEIVE_PROJECTS_ERROR,
      });
    });
  });

  describe('removeProject', () => {
    const mockRemovePath = 'mock-removePath';

    it('calls project removal path and fetches projects on success', () => {
      mockAxios.onDelete(mockRemovePath).replyOnce(HTTP_STATUS_OK);

      return testAction(
        actions.removeProject,
        mockRemovePath,
        null,
        [],
        [{ type: 'receiveRemoveProjectSuccess' }],
      );
    });

    it('passes off handling of project removal errors', () => {
      mockAxios.onDelete(mockRemovePath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      return testAction(
        actions.removeProject,
        mockRemovePath,
        null,
        [],
        [{ type: 'receiveRemoveProjectError' }],
      );
    });
  });

  describe('receiveRemoveProjectSuccess', () => {
    it('fetches dashboard projects', () => {
      return testAction(
        actions.receiveRemoveProjectSuccess,
        null,
        null,
        [],
        [{ type: 'forceProjectsRequest' }],
      );
    });
  });

  describe('receiveRemoveProjectError', () => {
    it('displays project removal error', () => {
      return testAction(actions.receiveRemoveProjectError, null, null, [], []).then(() => {
        expect(createAlert).toHaveBeenCalledWith({
          message: mockText.REMOVE_PROJECT_ERROR,
        });
      });
    });
  });

  describe('fetchSearchResults', () => {
    it('dispatches minimumQueryMessage if the search query is falsy', () => {
      const searchQueries = [null, undefined, false, NaN];

      return Promise.all(
        searchQueries.map((searchQuery) => {
          store.state.searchQuery = searchQuery;

          return testAction(
            actions.fetchSearchResults,
            null,
            store.state,
            [],
            [
              {
                type: 'requestSearchResults',
              },
              {
                type: 'minimumQueryMessage',
              },
            ],
          );
        }),
      );
    });

    it('dispatches minimumQueryMessage if the search query was empty', () => {
      store.state.searchQuery = '';

      return testAction(
        actions.fetchSearchResults,
        null,
        store.state,
        [],
        [
          {
            type: 'requestSearchResults',
          },
          {
            type: 'minimumQueryMessage',
          },
        ],
      );
    });

    it(`dispatches minimumQueryMessage if the search query wasn't long enough`, () => {
      store.state.searchQuery = 'a';

      return testAction(
        actions.fetchSearchResults,
        null,
        store.state,
        [],
        [
          {
            type: 'requestSearchResults',
          },
          {
            type: 'minimumQueryMessage',
          },
        ],
      );
    });

    it(`dispatches the correct actions when the query is valid`, () => {
      mockAxios.onAny().reply(HTTP_STATUS_OK, mockProjects, mockHeaders);
      store.state.searchQuery = 'mock-query';

      return testAction(
        actions.fetchSearchResults,
        null,
        store.state,
        [],
        [
          {
            type: 'requestSearchResults',
          },
          {
            type: 'receiveSearchResultsSuccess',
            payload: { data: mockProjects, headers: mockHeaders },
          },
        ],
      );
    });
  });

  describe('fetchNextPage', () => {
    it(`fetches the next page`, () => {
      mockAxios.onAny().reply(HTTP_STATUS_OK, mockProjects, mockHeaders);
      store.state.pageInfo = mockHeaders.pageInfo;

      return testAction(
        actions.fetchNextPage,
        null,
        store.state,
        [],
        [
          {
            type: 'receiveNextPageSuccess',
            payload: { data: mockProjects, headers: mockHeaders },
          },
        ],
      );
    });

    it(`stops fetching if current page is the last page`, () => {
      mockAxios.onAny().reply(HTTP_STATUS_OK, mockProjects, mockHeaders);
      store.state.pageInfo.totalPages = 3;
      store.state.pageInfo.currentPage = 3;

      return testAction(actions.fetchNextPage, mockHeaders, store.state, [], []);
    });
  });

  describe('requestSearchResults', () => {
    it(`commits the REQUEST_SEARCH_RESULTS mutation`, () => {
      return testAction(
        actions.requestSearchResults,
        null,
        store.state,
        [
          {
            type: types.REQUEST_SEARCH_RESULTS,
          },
        ],
        [],
      );
    });
  });

  describe('receiveNextPageSuccess', () => {
    it(`commits the RECEIVE_NEXT_PAGE_SUCCESS mutation`, () => {
      return testAction(
        actions.receiveNextPageSuccess,
        mockHeaders,
        store.state,
        [
          {
            type: types.RECEIVE_NEXT_PAGE_SUCCESS,
            payload: mockHeaders,
          },
        ],
        [],
      );
    });
  });

  describe('receiveSearchResultsSuccess', () => {
    it('commits the RECEIVE_SEARCH_RESULTS_SUCCESS mutation', () => {
      return testAction(
        actions.receiveSearchResultsSuccess,
        mockProjects,
        store.state,
        [
          {
            type: types.RECEIVE_SEARCH_RESULTS_SUCCESS,
            payload: mockProjects,
          },
        ],
        [],
      );
    });
  });

  describe('receiveSearchResultsError', () => {
    it('commits the RECEIVE_SEARCH_RESULTS_ERROR mutation', () => {
      return testAction(
        actions.receiveSearchResultsError,
        ['error'],
        store.state,
        [
          {
            type: types.RECEIVE_SEARCH_RESULTS_ERROR,
          },
        ],
        [],
      );
    });
  });

  describe('setProjectEndpoints', () => {
    it('commits project list and add endpoints', () => {
      return testAction(
        actions.setProjectEndpoints,
        {
          add: mockAddEndpoint,
          list: mockListEndpoint,
        },
        store.state,
        [
          {
            type: types.SET_PROJECT_ENDPOINT_LIST,
            payload: mockListEndpoint,
          },
          {
            type: types.SET_PROJECT_ENDPOINT_ADD,
            payload: mockAddEndpoint,
          },
        ],
        [],
      );
    });
  });

  describe('paginateDashboard', () => {
    it('fetches a new page of projects', () => {
      const newPage = 2;

      return testAction(
        actions.paginateDashboard,
        newPage,
        store.state,
        [],
        [
          {
            type: 'stopProjectsPolling',
          },
          {
            type: 'clearProjectsEtagPoll',
          },
          {
            type: 'fetchProjects',
            payload: newPage,
          },
        ],
      );
    });
  });
});
