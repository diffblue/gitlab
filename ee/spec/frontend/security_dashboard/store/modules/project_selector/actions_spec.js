import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/security_dashboard/store/modules/project_selector/actions';
import * as types from 'ee/security_dashboard/store/modules/project_selector/mutation_types';
import createState from 'ee/security_dashboard/store/modules/project_selector/state';
import testAction from 'helpers/vuex_action_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/flash');

describe('EE projectSelector actions', () => {
  const getMockProjects = (n) => [...Array(n).keys()].map((i) => ({ id: i, name: `project-${i}` }));

  const mockAddEndpoint = 'mock-add_endpoint';
  const mockListEndpoint = 'mock-list_endpoint';
  const mockResponse = { data: 'mock-data' };

  let mockAxios;
  let mockDispatchContext;
  let state;

  const pageInfo = {
    page: 1,
    nextPage: 2,
    total: 50,
    totalPages: 5,
  };

  const responseHeaders = {
    'X-Next-Page': pageInfo.nextPage,
    'X-Page': pageInfo.page,
    'X-Total': pageInfo.total,
    'X-Total-Pages': pageInfo.totalPages,
  };

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockDispatchContext = { dispatch: () => {}, commit: () => {}, state };
    state = createState();
  });

  afterEach(() => {
    mockAxios.restore();
  });

  describe('toggleSelectedProject', () => {
    it('adds a project to selectedProjects if it does not already exist in the list', async () => {
      const payload = getMockProjects(1);

      await testAction(
        actions.toggleSelectedProject,
        payload,
        state,
        [
          {
            type: types.SELECT_PROJECT,
            payload,
          },
        ],
        [],
      );
    });

    it('removes a project from selectedProjects if it already exist in the list', async () => {
      const payload = getMockProjects(1)[0];
      state.selectedProjects = getMockProjects(1);

      await testAction(
        actions.toggleSelectedProject,
        payload,
        state,
        [
          {
            type: types.DESELECT_PROJECT,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('addProjects', () => {
    it(`posts the selected project's ids to the add-endpoint`, () => {
      const projectIds = ['1', '2'];

      state.selectedProjects = [
        { id: projectIds[0], name: '1' },
        { id: projectIds[1], name: '2' },
      ];
      state.projectEndpoints.add = mockAddEndpoint;

      mockAxios.onPost(mockAddEndpoint).replyOnce(200, mockResponse);

      actions.addProjects({ state, dispatch: () => {} });

      return waitForPromises().then(() => {
        const requestData = mockAxios.history.post[0].data;
        expect(requestData).toBe(JSON.stringify({ project_ids: projectIds }));
      });
    });

    it('dispatches the correct actions when the request is successful', async () => {
      state.projectEndpoints.add = mockAddEndpoint;

      mockAxios.onPost(mockAddEndpoint).replyOnce(200, mockResponse);

      await testAction(
        actions.addProjects,
        null,
        state,
        [],
        [
          {
            type: 'requestAddProjects',
          },
          {
            type: 'receiveAddProjectsSuccess',
            payload: mockResponse,
          },
          {
            type: 'clearSearchResults',
          },
        ],
      );
    });

    it('calls addProjects error handler on error', () => {
      mockAxios.onPost(mockAddEndpoint).replyOnce(500);

      return testAction(
        actions.addProjects,
        null,
        state,
        [],
        [
          { type: 'requestAddProjects' },
          { type: 'receiveAddProjectsError' },
          { type: 'clearSearchResults' },
        ],
      );
    });
  });

  describe('requestAddProjects', () => {
    it('commits the REQUEST_ADD_PROJECTS mutation', () =>
      testAction(
        actions.requestAddProjects,
        null,
        state,
        [
          {
            type: types.REQUEST_ADD_PROJECTS,
          },
        ],
        [],
      ));
  });

  describe('receiveAddProjectsSuccess', () => {
    beforeEach(() => {
      state.selectedProjects = getMockProjects(3);
    });

    it('fetches projects when new projects are added to the dashboard', () => {
      const addedProject = state.selectedProjects[0];
      const payload = {
        added: [addedProject.id],
        invalid: [],
        duplicate: [],
      };

      return testAction(
        actions.receiveAddProjectsSuccess,
        payload,
        state,
        [{ type: types.RECEIVE_ADD_PROJECTS_SUCCESS }],
        [
          {
            type: 'fetchProjects',
          },
        ],
      );
    });

    it('displays an error when user tries to add one invalid project to dashboard', () => {
      const invalidProject = state.selectedProjects[0];
      const payload = {
        added: [],
        invalid: [invalidProject.id],
      };

      return testAction(
        actions.receiveAddProjectsSuccess,
        payload,
        state,
        [{ type: types.RECEIVE_ADD_PROJECTS_SUCCESS }],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalledWith({
          message: `Unable to add ${invalidProject.name}`,
        });
      });
    });

    it('displays an error when user tries to add two invalid projects to dashboard', () => {
      const invalidProject1 = state.selectedProjects[0];
      const invalidProject2 = state.selectedProjects[1];
      const payload = {
        added: [],
        invalid: [invalidProject1.id, invalidProject2.id],
      };

      return testAction(
        actions.receiveAddProjectsSuccess,
        payload,
        state,
        [{ type: types.RECEIVE_ADD_PROJECTS_SUCCESS }],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalledWith({
          message: `Unable to add ${invalidProject1.name} and ${invalidProject2.name}`,
        });
      });
    });

    it('displays an error when user tries to add more than two invalid projects to dashboard', () => {
      const invalidProject1 = state.selectedProjects[0];
      const invalidProject2 = state.selectedProjects[1];
      const invalidProject3 = state.selectedProjects[2];
      const payload = {
        added: [],
        invalid: [invalidProject1.id, invalidProject2.id, invalidProject3.id],
      };

      return testAction(
        actions.receiveAddProjectsSuccess,
        payload,
        state,
        [{ type: types.RECEIVE_ADD_PROJECTS_SUCCESS }],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalledWith({
          message: `Unable to add ${invalidProject1.name}, ${invalidProject2.name}, and ${invalidProject3.name}`,
        });
      });
    });
  });

  describe('receiveAddProjectsError', () => {
    it('commits RECEIVE_ADD_PROJECTS_ERROR', () =>
      testAction(
        actions.receiveAddProjectsError,
        null,
        state,
        [
          {
            type: types.RECEIVE_ADD_PROJECTS_ERROR,
          },
        ],
        [],
      ));

    it('shows error message', () => {
      actions.receiveAddProjectsError(mockDispatchContext);

      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Something went wrong, unable to add projects to dashboard',
      });
    });
  });

  describe('clearSearchResults', () => {
    it('clears all project search results', () =>
      testAction(
        actions.clearSearchResults,
        null,
        state,
        [
          {
            type: types.CLEAR_SEARCH_RESULTS,
          },
        ],
        [],
      ));
  });

  describe('fetchProjects', () => {
    it('calls project list endpoint', () => {
      state.projectEndpoints.list = mockListEndpoint;
      mockAxios.onGet(mockListEndpoint).replyOnce(200, mockResponse);

      return testAction(
        actions.fetchProjects,
        null,
        state,
        [],
        [{ type: 'requestProjects' }, { type: 'receiveProjectsSuccess', payload: mockResponse }],
      );
    });

    it('handles response errors', () => {
      state.projectEndpoints.list = mockListEndpoint;
      mockAxios.onGet(mockListEndpoint).replyOnce(500);

      return testAction(
        actions.fetchProjects,
        null,
        state,
        [],
        [{ type: 'requestProjects' }, { type: 'receiveProjectsError' }],
      );
    });
  });

  describe('requestProjects', () => {
    it('toggles project loading state', () =>
      testAction(actions.requestProjects, null, state, [{ type: types.REQUEST_PROJECTS }], []));
  });

  describe('receiveProjectsSuccess', () => {
    it('sets projects from data on success', () => {
      const payload = {
        projects: [{ id: 0, name: 'mock-name1' }],
      };

      return testAction(
        actions.receiveProjectsSuccess,
        payload,
        state,
        [
          {
            type: types.RECEIVE_PROJECTS_SUCCESS,
            payload: payload.projects,
          },
        ],
        [],
      );
    });
  });

  describe('receiveProjectsError', () => {
    it('clears projects and alerts user of error', () =>
      testAction(
        actions.receiveProjectsError,
        null,
        state,
        [
          {
            type: types.RECEIVE_PROJECTS_ERROR,
          },
        ],
        [],
      ).then(() => {
        expect(createFlash).toHaveBeenCalledWith({
          message: 'Something went wrong, unable to get projects',
        });
      }));
  });

  describe('removeProject', () => {
    const mockRemovePath = 'mock-removePath';

    it('calls project removal path and fetches projects on success', () => {
      mockAxios.onDelete(mockRemovePath).replyOnce(200);

      return testAction(
        actions.removeProject,
        mockRemovePath,
        null,
        [],
        [{ type: 'requestRemoveProject' }, { type: 'receiveRemoveProjectSuccess' }],
      );
    });

    it('passes off handling of project removal errors', () => {
      mockAxios.onDelete(mockRemovePath).replyOnce(500);

      return testAction(
        actions.removeProject,
        mockRemovePath,
        null,
        [],
        [{ type: 'requestRemoveProject' }, { type: 'receiveRemoveProjectError' }],
      );
    });
  });

  describe('requestRemoveProject', () => {
    it('commits REQUEST_REMOVE_PROJECT mutation', () =>
      testAction(
        actions.requestRemoveProject,
        null,
        state,
        [
          {
            type: types.REQUEST_REMOVE_PROJECT,
          },
        ],
        [],
      ));
  });

  describe('receiveRemoveProjectSuccess', () => {
    it('commits RECEIVE_REMOVE_PROJECT_SUCCESS mutation and dispatches fetchProjects', () =>
      testAction(
        actions.receiveRemoveProjectSuccess,
        null,
        state,
        [
          {
            type: types.RECEIVE_REMOVE_PROJECT_SUCCESS,
          },
        ],
        [{ type: 'fetchProjects' }],
      ));
  });

  describe('receiveRemoveProjectError', () => {
    it('commits REQUEST_REMOVE_PROJECT mutation', () =>
      testAction(
        actions.receiveRemoveProjectError,
        null,
        state,
        [
          {
            type: types.RECEIVE_REMOVE_PROJECT_ERROR,
          },
        ],
        [],
      ));

    it('displays project removal error', () => {
      actions.receiveRemoveProjectError(mockDispatchContext);

      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Something went wrong, unable to delete project',
      });
    });
  });

  describe('setSearchQuery', () => {
    it('commits the REQUEST_SEARCH_RESULTS mutation', () => {
      const payload = 'search-query';

      return testAction(
        actions.setSearchQuery,
        payload,
        state,
        [
          {
            type: types.SET_SEARCH_QUERY,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('fetchSearchResults', () => {
    it.each([null, undefined, false, NaN, 0, ''])(
      'dispatches setMinimumQueryMessage if the search query is falsy',
      (searchQuery) => {
        state.searchQuery = searchQuery;

        return testAction(
          actions.fetchSearchResults,
          null,
          state,
          [],
          [
            {
              type: 'requestSearchResults',
            },
            {
              type: 'setMinimumQueryMessage',
            },
          ],
        );
      },
    );

    it.each(['a', 'aa'])(
      'dispatches setMinimumQueryMessage if the search query was not long enough',
      (shortSearchQuery) => {
        state.searchQuery = shortSearchQuery;

        return testAction(
          actions.fetchSearchResults,
          null,
          state,
          [],
          [
            {
              type: 'requestSearchResults',
            },
            {
              type: 'setMinimumQueryMessage',
            },
          ],
        );
      },
    );

    it('dispatches the correct actions when the query is valid', () => {
      const projects = [{ id: 0, name: 'mock-name1' }];

      mockAxios.onGet().replyOnce(200, projects, responseHeaders);
      state.searchQuery = 'mock-query';

      return testAction(
        actions.fetchSearchResults,
        null,
        state,
        [
          {
            type: types.RECEIVE_SEARCH_RESULTS_SUCCESS,
            payload: { data: projects, headers: responseHeaders, pageInfo },
          },
        ],
        [
          {
            type: 'requestSearchResults',
          },
        ],
      );
    });

    it('dispatches the correct actions when the request is not successful', () => {
      mockAxios.onGet(mockListEndpoint).replyOnce(500);

      state.searchQuery = 'mock-query';

      testAction(
        actions.fetchSearchResults,
        null,
        state,
        [],
        [
          {
            type: 'requestSearchResults',
          },
          {
            type: 'receiveSearchResultsError',
          },
        ],
      );
    });
  });

  describe('requestSearchResults', () => {
    it('commits the REQUEST_SEARCH_RESULTS mutation', () =>
      testAction(
        actions.requestSearchResults,
        null,
        state,
        [
          {
            type: types.REQUEST_SEARCH_RESULTS,
          },
        ],
        [],
      ));
  });

  describe('receiveSearchResultsError', () => {
    it('commits the RECEIVE_SEARCH_RESULTS_ERROR mutation', () =>
      testAction(
        actions.receiveSearchResultsError,
        ['error'],
        state,
        [
          {
            type: types.RECEIVE_SEARCH_RESULTS_ERROR,
          },
        ],
        [],
      ));
  });

  describe('setProjectEndpoints', () => {
    it('commits project list and add endpoints', () => {
      const payload = {
        add: 'add',
        list: 'list',
      };

      return testAction(
        actions.setProjectEndpoints,
        payload,
        state,
        [
          {
            type: types.SET_PROJECT_ENDPOINTS,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe('setMinimumQueryMessage', () => {
    it('commits the SET_MINIMUM_QUERY_MESSAGE mutation', () =>
      testAction(
        actions.setMinimumQueryMessage,
        null,
        state,
        [
          {
            type: types.SET_MINIMUM_QUERY_MESSAGE,
          },
        ],
        [],
      ));
  });
});
