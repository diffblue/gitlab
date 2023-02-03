import MockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import {
  fetchProtectedEnvironments,
  fetchAllMembers,
  fetchMembers,
} from 'ee/protected_environments/store/edit/actions';
import * as types from 'ee/protected_environments/store/edit/mutation_types';
import { state } from 'ee/protected_environments/store/edit/state';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';

describe('ee/protected_environments/store/edit/actions', () => {
  let mockedState;
  let mock;
  let originalGon;

  beforeEach(() => {
    mockedState = state({ projectId: '8' });
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = { api_version: 'v4' };
  });

  afterEach(() => {
    mock.restore();
    mock.resetHistory();
    window.gon = originalGon;
  });

  describe('fetchProtectedEnvironments', () => {
    it('successfully calls the protected environments API and saves the result', () => {
      const environments = [{ name: 'staging' }];
      mock.onGet().replyOnce(HTTP_STATUS_OK, environments);
      return testAction(
        fetchProtectedEnvironments,
        undefined,
        mockedState,
        [
          { type: types.REQUEST_PROTECTED_ENVIRONMENTS },
          { type: types.RECEIVE_PROTECTED_ENVIRONMENTS_SUCCESS, payload: environments },
        ],
        [{ type: 'fetchAllMembers' }],
      );
    });

    it('saves the error on failure', () => {
      mock.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      return testAction(
        fetchProtectedEnvironments,
        undefined,
        mockedState,
        [
          { type: types.REQUEST_PROTECTED_ENVIRONMENTS },
          { type: types.RECEIVE_PROTECTED_ENVIRONMENTS_ERROR, payload: expect.any(Error) },
        ],
        [],
      );
    });
  });

  describe('fetchAllMembers', () => {
    it('successfully fetches members for every deploy access rule in every environment', () => {
      const deployLevelsForStaging = [{ group_id: 1 }, { user_id: 1 }];
      const deployLevelsForProduction = [{ group_id: 2 }, { user_id: 2 }];
      const environments = [
        { name: 'staging', deploy_access_levels: deployLevelsForStaging },
        { name: 'production', deploy_access_levels: deployLevelsForProduction },
      ];

      mockedState.protectedEnvironments = environments;

      mock.onGet().replyOnce(HTTP_STATUS_OK, environments);

      return testAction(
        fetchAllMembers,
        undefined,
        mockedState,
        [{ type: types.REQUEST_MEMBERS }, { type: types.RECEIVE_MEMBERS_FINISH }],
        [
          ...environments.flatMap((env) =>
            env.deploy_access_levels.map((rule) => ({ type: 'fetchMembers', payload: rule })),
          ),
        ],
      );
    });
  });

  describe('fetchMembers', () => {
    it.each`
      type              | rule                                                                                | url                               | response
      ${'group'}        | ${{ group_id: 1, user_id: null, access_level: null, group_inheritance_type: '1' }}  | ${'/api/v4/groups/1/members/all'} | ${[{ name: 'root' }]}
      ${'user'}         | ${{ group_id: null, user_id: 1, access_level: null, group_ineritance_type: null }}  | ${'/api/v4/users/1'}              | ${{ name: 'root' }}
      ${'access level'} | ${{ group_id: null, user_id: null, access_level: 40, group_inheritance_type: '0' }} | ${'/api/v4/projects/8/members'}   | ${[{ name: 'root', access_level: '40' }]}
    `(
      'successfully fetches members for a given deploy access rule of type $type',
      ({ rule, url, response }) => {
        mock.onGet(url).replyOnce(HTTP_STATUS_OK, response);

        return testAction(
          fetchMembers,
          rule,
          mockedState,
          [{ type: types.RECEIVE_MEMBER_SUCCESS, payload: { rule, users: [].concat(response) } }],
          [],
        );
      },
    );

    it('filters out users that do not meet the requested deploy access level for access level rules', () => {
      const rule = { group_id: null, user_id: null, access_level: 40, group_inheritance_type: '0' };

      const url = '/api/v4/projects/8/members';
      const root = { name: 'root', access_level: '40' };
      const response = [root, { name: 'alice', access_level: '30' }];

      mock.onGet(url).replyOnce(HTTP_STATUS_OK, response);

      return testAction(
        fetchMembers,
        rule,
        mockedState,
        [{ type: types.RECEIVE_MEMBER_SUCCESS, payload: { rule, users: [root] } }],
        [],
      );
    });

    it('saves the error on a failure', () => {
      mock.onGet().replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      const rule = { group_id: null, user_id: null, access_level: 40, group_inheritance_type: '0' };

      return testAction(
        fetchMembers,
        rule,
        mockedState,
        [{ type: types.RECEIVE_MEMBERS_ERROR, payload: expect.any(Error) }],
        [],
      );
    });
  });
});
