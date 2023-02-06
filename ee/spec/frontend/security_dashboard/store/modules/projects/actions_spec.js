import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/security_dashboard/store/modules/projects/actions';
import * as types from 'ee/security_dashboard/store/modules/projects/mutation_types';
import createState from 'ee/security_dashboard/store/modules/projects/state';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';

import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import mockData from './data/mock_data.json';

describe('projects actions', () => {
  const data = mockData;
  const endpoint = `${TEST_HOST}/projects.json`;

  describe('fetchProjects', () => {
    let mock;
    const state = createState();

    beforeEach(() => {
      state.projectsEndpoint = endpoint;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      const expectedParams = {
        include_subgroups: true,
        with_security_reports: true,
        with_shared: false,
      };

      beforeEach(() => {
        mock.onGet(state.projectsEndpoint).replyOnce((config) => {
          const hasExpectedParams = Object.keys(expectedParams).every(
            (param) => config.params[param] === expectedParams[param],
          );

          return hasExpectedParams ? [HTTP_STATUS_OK, data] : [HTTP_STATUS_BAD_REQUEST];
        });
      });

      it('should dispatch the request and success actions', async () => {
        await testAction(
          actions.fetchProjects,
          {},
          state,
          [],
          [
            { type: 'requestProjects' },
            {
              type: 'receiveProjectsSuccess',
              payload: { projects: data },
            },
          ],
        );
      });
    });

    describe('calls the API multiple times if there is a next page', () => {
      beforeEach(() => {
        mock
          .onGet(state.projectsEndpoint, { page: '1' })
          .replyOnce(HTTP_STATUS_OK, [1], { 'x-next-page': '2' });

        mock.onGet(state.projectsEndpoint, { page: '2' }).replyOnce(HTTP_STATUS_OK, [2]);
      });

      it('should dispatch the request and success actions', async () => {
        await testAction(
          actions.fetchProjects,
          {},
          state,
          [],
          [
            { type: 'requestProjects' },
            {
              type: 'receiveProjectsSuccess',
              payload: { projects: [1, 2] },
            },
          ],
        );
      });
    });

    describe('on error', () => {
      beforeEach(() => {
        mock.onGet(state.projectsEndpoint).replyOnce(HTTP_STATUS_NOT_FOUND, {});
      });

      it('should dispatch the request and error actions', async () => {
        await testAction(
          actions.fetchProjects,
          {},
          state,
          [],
          [{ type: 'requestProjects' }, { type: 'receiveProjectsError' }],
        );
      });
    });

    describe('with an empty endpoint', () => {
      beforeEach(() => {
        state.projectsEndpoint = '';
      });

      it('should not do anything', async () => {
        await testAction(actions.fetchProjects, {}, state, [], []);
      });
    });
  });

  describe('receiveProjectsSuccess', () => {
    it('should commit the success mutation', async () => {
      const state = createState();

      await testAction(
        actions.receiveProjectsSuccess,
        { projects: data },
        state,
        [
          {
            type: types.RECEIVE_PROJECTS_SUCCESS,
            payload: { projects: data },
          },
        ],
        [],
      );
    });
  });

  describe('receiveProjectsError', () => {
    it('should commit the error mutation', async () => {
      const state = createState();

      await testAction(
        actions.receiveProjectsError,
        {},
        state,
        [{ type: types.RECEIVE_PROJECTS_ERROR }],
        [],
      );
    });
  });

  describe('requestProjects', () => {
    it('should commit the request mutation', async () => {
      const state = createState();

      await testAction(actions.requestProjects, {}, state, [{ type: types.REQUEST_PROJECTS }], []);
    });
  });

  describe('setProjectsEndpoint', () => {
    it('should commit the correct mutuation', async () => {
      const state = createState();

      await testAction(
        actions.setProjectsEndpoint,
        endpoint,
        state,
        [
          {
            type: types.SET_PROJECTS_ENDPOINT,
            payload: endpoint,
          },
        ],
        [],
      );
    });
  });
});
