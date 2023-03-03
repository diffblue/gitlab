import * as types from 'ee/vue_shared/dashboards/store/mutation_types';
import mutations from 'ee/vue_shared/dashboards/store/mutations';
import state from 'ee/vue_shared/dashboards/store/state';
import { mockProjectData } from 'ee_jest/vue_shared/dashboards/mock_data';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { createAlert, VARIANT_WARNING } from '~/alert';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

jest.mock('~/alert');

describe('mutations', () => {
  useLocalStorageSpy();

  const projects = mockProjectData(3);
  const projectIds = projects.map((p) => p.id);
  const mockEndpoint = 'https://mock-endpoint';
  let localState;

  beforeEach(() => {
    localState = state();
  });

  describe('SET_PROJECT_ENDPOINT_LIST', () => {
    it('sets project list endpoint', () => {
      mutations[types.SET_PROJECT_ENDPOINT_LIST](localState, mockEndpoint);

      expect(localState.projectEndpoints.list).toBe(mockEndpoint);
    });
  });

  describe('SET_PROJECT_ENDPOINT_ADD', () => {
    it('sets project add endpoint', () => {
      mutations[types.SET_PROJECT_ENDPOINT_ADD](localState, mockEndpoint);

      expect(localState.projectEndpoints.add).toBe(mockEndpoint);
    });
  });

  describe('SET_PROJECTS', () => {
    beforeEach(() => {
      localState.projectEndpoints.list = 'listEndpoint';
    });

    it('sets projects', () => {
      mutations[types.SET_PROJECTS](localState, projects);

      expect(localState.projects).toEqual(projects);
      expect(localState.isLoadingProjects).toEqual(false);
    });

    it('stores project IDs in localstorage', () => {
      mutations[types.SET_PROJECTS](localState, projects);

      expect(window.localStorage.setItem).toHaveBeenCalledWith('listEndpoint', projectIds);
    });

    it('shows warning Alert if localStorage not available', () => {
      jest.spyOn(window.localStorage, 'setItem').mockImplementation(() => {
        throw new Error('QUOTA_EXCEEDED_ERR: DOM Exception 22');
      });

      mutations[types.SET_PROJECTS](localState, projects);

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Project order will not be saved as local storage is not available.',
        variant: VARIANT_WARNING,
      });
    });
  });

  describe('SET_MESSAGE_MINIMUM_QUERY', () => {
    it('sets the messages.minimumQuery boolean', () => {
      mutations[types.SET_MESSAGE_MINIMUM_QUERY](localState, true);

      expect(localState.messages.minimumQuery).toEqual(true);

      mutations[types.SET_MESSAGE_MINIMUM_QUERY](localState, false);
    });
  });

  describe('SET_SEARCH_QUERY', () => {
    it('sets the search query', () => {
      const mockQuery = 'mock-query';
      mutations[types.SET_SEARCH_QUERY](localState, mockQuery);

      expect(localState.searchQuery).toBe(mockQuery);
    });
  });

  describe('ADD_SELECTED_PROJECT', () => {
    it('adds a project to the list of selected projects', () => {
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[0]);

      expect(localState.selectedProjects).toEqual([projects[0]]);
    });
  });

  describe('REMOVE_SELECTED_PROJECT', () => {
    it('removes a project from the list of selected projects', () => {
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[0]);
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[1]);
      mutations[types.REMOVE_SELECTED_PROJECT](localState, projects[0]);

      expect(localState.selectedProjects).toEqual([projects[1]]);
    });

    it('removes a project from the list of selected projects, including duplicates', () => {
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[0]);
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[0]);
      mutations[types.ADD_SELECTED_PROJECT](localState, projects[1]);
      mutations[types.REMOVE_SELECTED_PROJECT](localState, projects[0]);

      expect(localState.selectedProjects).toEqual([projects[1]]);
    });
  });

  describe('RECEIVE_PROJECTS_SUCCESS', () => {
    const projectListEndpoint = 'projectListEndpoint';

    beforeEach(() => {
      localState.projectEndpoints.list = projectListEndpoint;
    });

    it('sets the project list and clears the loading status', () => {
      mutations[types.RECEIVE_PROJECTS_SUCCESS](localState, { projects });

      expect(localState.projects).toEqual(projects);
      expect(localState.isLoadingProjects).toBe(false);
    });

    it('saves projects to localStorage', () => {
      mutations[types.RECEIVE_PROJECTS_SUCCESS](localState, { projects });

      expect(window.localStorage.setItem).toHaveBeenCalledWith(projectListEndpoint, projectIds);
    });

    it('orders the projects from localstorage', () => {
      jest.spyOn(window.localStorage, 'getItem').mockImplementation((key) => {
        if (key === projectListEndpoint) {
          return '2,0,1';
        }
        return null;
      });
      const expectedOrder = [projects[2], projects[0], projects[1]];

      mutations[types.RECEIVE_PROJECTS_SUCCESS](localState, { projects });

      expect(localState.projects).toEqual(expectedOrder);
    });

    it('places unsorted projects after sorted ones', () => {
      jest.spyOn(window.localStorage, 'getItem').mockImplementation((key) => {
        if (key === projectListEndpoint) {
          return '1,2';
        }
        return null;
      });
      const expectedOrder = [projects[1], projects[2], projects[0]];

      mutations[types.RECEIVE_PROJECTS_SUCCESS](localState, { projects });

      expect(localState.projects).toEqual(expectedOrder);
    });

    it('sets dashbpard pagination state', () => {
      const headers = {
        'x-page': 1,
        'x-per-page': 20,
        'x-next-page': 2,
        'x-total': 22,
        'x-total-pages': 2,
        'x-prev-page': null,
      };

      mutations[types.RECEIVE_PROJECTS_SUCCESS](localState, { projects, headers });

      const expectedHeaders = parseIntPagination(normalizeHeaders(headers));
      expect(localState.projectsPage.pageInfo).toEqual(expectedHeaders);
    });
  });

  describe('RECEIVE_PROJECTS_ERROR', () => {
    it('clears project list and the loading status', () => {
      mutations[types.RECEIVE_PROJECTS_ERROR](localState);

      expect(localState.projects).toEqual(null);

      expect(localState.isLoadingProjects).toBe(false);
    });
  });

  describe('CLEAR_SEARCH_RESULTS', () => {
    it('empties both the search results and the list of selected projects', () => {
      localState.selectedProjects = [{ id: 1 }];
      localState.projectSearchResults = [{ id: 1 }];

      mutations[types.CLEAR_SEARCH_RESULTS](localState);

      expect(localState.projectSearchResults).toEqual([]);

      expect(localState.selectedProjects).toEqual([]);
    });
  });

  describe('REQUEST_SEARCH_RESULTS', () => {
    it('turns off the minimum length warning and increments the search count', () => {
      mutations[types.REQUEST_SEARCH_RESULTS](localState);

      expect(localState.messages.minimumQuery).toBe(false);

      expect(localState.searchCount).toEqual(1);
    });
  });

  describe('RECEIEVE_NEXT_PAGE_SUCESS', () => {
    it('sets the nextPage and currentPage of results', () => {
      localState.projectSearchResults = [{ id: 1 }];
      const headers = {
        'x-next-page': '3',
        'x-page': '2',
      };
      const results = { data: projects[1], headers };

      mutations[types.RECEIVE_NEXT_PAGE_SUCCESS](localState, results);

      expect(localState.projectSearchResults.length).toEqual(2);
      expect(localState.pageInfo.currentPage).toEqual(2);
      expect(localState.pageInfo.nextPage).toEqual(3);
    });
  });

  describe('RECEIVE_SEARCH_RESULTS_SUCCESS', () => {
    it('resets all messages, sets page info, and sets state.projectSearchResults to the results from the API', () => {
      localState.projectSearchResults = [];
      localState.messages = {
        noResults: true,
        searchError: true,
        minimumQuery: true,
      };

      const results = {
        data: [{ id: 1 }],
        headers: {
          'x-next-page': '2',
          'x-page': '1',
          'X-Total': '37',
          'X-Total-Pages': '2',
        },
      };

      mutations[types.RECEIVE_SEARCH_RESULTS_SUCCESS](localState, results);

      expect(localState.projectSearchResults).toEqual(results.data);
      expect(localState.messages.noResults).toBe(false);
      expect(localState.messages.searchError).toBe(false);
      expect(localState.pageInfo).toEqual({
        currentPage: 1,
        nextPage: 2,
        totalPages: 2,
        totalResults: 37,
      });
    });

    it('resets all messages and pageInfo and sets state.projectSearchResults to an empty array if no results', () => {
      localState.projectSearchResults = [];
      localState.messages = {
        noResults: false,
        searchError: true,
        minimumQuery: true,
      };

      const results = { data: [], headers: { 'x-total': 0 } };

      mutations[types.RECEIVE_SEARCH_RESULTS_SUCCESS](localState, results);

      expect(localState.projectSearchResults).toEqual(results.data);

      expect(localState.messages.noResults).toBe(true);

      expect(localState.messages.searchError).toBe(false);

      expect(localState.messages.minimumQuery).toBe(false);

      expect(localState.pageInfo.totalResults).toEqual(0);
    });

    it('decrements the search count by one', () => {
      localState.searchCount = 1;
      const results = { data: [], headers: {} };

      mutations[types.RECEIVE_SEARCH_RESULTS_SUCCESS](localState, results);

      expect(localState.searchCount).toBe(0);
    });

    it('does not decrement the search count to be negative', () => {
      localState.searchCount = 0;
      const results = { data: [], headers: {} };

      mutations[types.RECEIVE_SEARCH_RESULTS_SUCCESS](localState, results);

      expect(localState.searchCount).toBe(0);
    });
  });

  describe('RECEIVE_SEARCH_RESULTS_ERROR', () => {
    it('clears the search results', () => {
      mutations[types.RECEIVE_SEARCH_RESULTS_ERROR](localState);

      expect(localState.projectSearchResults).toEqual([]);

      expect(localState.messages.noResults).toBe(false);

      expect(localState.messages.searchError).toBe(true);

      expect(localState.messages.minimumQuery).toBe(false);
    });

    it('decrements the search count by one', () => {
      localState.searchCount = 1;

      mutations[types.RECEIVE_SEARCH_RESULTS_ERROR](localState);

      expect(localState.searchCount).toBe(0);
    });

    it('does not decrement the search count to be negative', () => {
      localState.searchCount = 0;

      mutations[types.RECEIVE_SEARCH_RESULTS_ERROR](localState);

      expect(localState.searchCount).toBe(0);
    });
  });

  describe('REQUEST_PROJECTS', () => {
    it('sets loading projects to true', () => {
      mutations[types.REQUEST_PROJECTS](localState);

      expect(localState.isLoadingProjects).toEqual(true);
    });
  });

  describe('MINIMUM_QUERY_MESSAGE', () => {
    beforeEach(() => {
      localState.projectSearchResults = ['result'];
      localState.messages.noResults = true;
      localState.messages.searchError = true;
      localState.messages.minimumQuery = false;
      localState.searchCount = 1;

      mutations[types.MINIMUM_QUERY_MESSAGE](localState);
    });

    it('clears the search results', () => {
      expect(localState.projectSearchResults).toEqual([]);
      expect(localState.messages.noResults).toBe(false);
    });

    it('turns off the search error message', () => {
      expect(localState.messages.searchError).toBe(false);
    });

    it('turns on the minimum length message', () => {
      expect(localState.messages.minimumQuery).toBe(true);
    });

    it('decrements the search count by one', () => {
      expect(localState.searchCount).toBe(0);
    });

    it('does not decrement the search count to be negative', () => {
      localState.searchCount = 0;

      mutations[types.MINIMUM_QUERY_MESSAGE](localState);

      expect(localState.searchCount).toBe(0);
    });
  });
});
