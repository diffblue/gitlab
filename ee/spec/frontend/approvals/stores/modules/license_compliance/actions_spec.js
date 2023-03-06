import MockAdapter from 'axios-mock-adapter';
import { mapApprovalSettingsResponse } from 'ee/approvals/mappers';
import * as baseMutationTypes from 'ee/approvals/stores/modules/base/mutation_types';
import * as actions from 'ee/approvals/stores/modules/license_compliance/actions';
import { createAlert } from '~/alert';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');

describe('EE approvals license-compliance actions', () => {
  let state;
  let axiosMock;

  const mocks = {
    state: {
      settingsPath: 'projects/9/approval_settings',
      rulesPath: 'projects/9/approval_settings/rules',
      projectPath: 'projects/9',
    },
  };

  beforeEach(() => {
    state = {
      settings: {
        settingsPath: mocks.state.settingsPath,
        rulesPath: mocks.state.rulesPath,
        projectPath: mocks.state.projectPath,
      },
    };
    axiosMock = new MockAdapter(axios);
  });

  describe('receiveRulesSuccess', () => {
    it('sets rules to given payload and "loading" to false', () => {
      const payload = {};

      return testAction(actions.receiveRulesSuccess, payload, state, [
        {
          type: baseMutationTypes.SET_APPROVAL_SETTINGS,
          payload,
        },
        {
          type: baseMutationTypes.SET_LOADING,
          payload: false,
        },
      ]);
    });
  });

  describe('fetchRules', () => {
    it('sets "loading" to be true and dispatches "receiveRuleSuccess"', () => {
      const responseData = { rules: [] };
      axiosMock.onGet(mocks.state.settingsPath).replyOnce(HTTP_STATUS_OK, responseData);

      return testAction(
        actions.fetchRules,
        null,
        state,
        [
          {
            type: baseMutationTypes.SET_LOADING,
            payload: true,
          },
        ],
        [
          {
            type: 'receiveRulesSuccess',
            payload: mapApprovalSettingsResponse(responseData.rules),
          },
        ],
      );
    });

    it('creates an alert error if the request is not successful', async () => {
      axiosMock.onGet(mocks.state.settingsPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await actions.fetchRules({ rootState: state, dispatch: () => {}, commit: () => {} });

      expect(createAlert).toHaveBeenNthCalledWith(1, { message: expect.any(String) });
    });
  });

  describe('postRule', () => {
    it('posts correct data and dispatches "fetchRules" when request is successful', async () => {
      const rule = {
        name: 'Foo',
        approvalsRequired: 1,
        users: [8, 9],
        groups: [7],
      };
      axiosMock.onPost(mocks.state.rulesPath).replyOnce(HTTP_STATUS_OK);

      await testAction(
        actions.postRule,
        rule,
        state,
        [],
        [
          {
            type: 'fetchRules',
          },
        ],
      );
      expect(axiosMock.history.post[0].data).toBe(
        '{"name":"Foo","approvals_required":1,"users":[8,9],"groups":[7]}',
      );
    });

    it('creates an alert error if the request is not successful', async () => {
      axiosMock.onPost(mocks.state.settingsPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await actions.postRule({ rootState: state, dispatch: () => {}, commit: () => {} }, []);

      expect(createAlert).toHaveBeenNthCalledWith(1, { message: expect.any(String) });
    });
  });

  describe('putRule', () => {
    const id = 4;
    const putUrl = `${mocks.state.rulesPath}/${4}`;

    it('puts correct data and dispatches "fetchRules" when request is successful', async () => {
      const payload = {
        id,
        name: 'Foo',
        approvalsRequired: 1,
        users: [8, 9],
        groups: [7],
      };
      axiosMock.onPut(putUrl).replyOnce(HTTP_STATUS_OK);

      await testAction(
        actions.putRule,
        payload,
        state,
        [],
        [
          {
            type: 'fetchRules',
          },
        ],
      );
      expect(axiosMock.history.put[0].data).toBe(
        '{"name":"Foo","approvals_required":1,"users":[8,9],"groups":[7]}',
      );
    });

    it('creates an alert error if the request is not successful', async () => {
      axiosMock.onPut(putUrl).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await actions.putRule({ rootState: state, dispatch: () => {} }, { id });

      expect(createAlert).toHaveBeenNthCalledWith(1, { message: expect.any(String) });
    });
  });

  describe('deleteRule', () => {
    const id = 0;
    const deleteUrl = `${mocks.state.rulesPath}/${id}`;

    it('dispatches "fetchRules" when the deletion is successful', () => {
      axiosMock.onDelete(deleteUrl).replyOnce(HTTP_STATUS_OK);

      return testAction(
        actions.deleteRule,
        id,
        state,
        [],
        [
          {
            type: 'fetchRules',
          },
        ],
      );
    });

    it('creates an alert error if the request is not successful', async () => {
      axiosMock.onDelete(deleteUrl).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await actions.deleteRule({ rootState: state, dispatch: () => {} }, deleteUrl);

      expect(createAlert).toHaveBeenNthCalledWith(1, { message: expect.any(String) });
    });
  });

  describe('putFallbackRule', () => {
    it('puts correct fallback-data and dispatches "fetchRules" when request is successful', () => {
      const payload = {
        name: 'Foo',
        approvalsRequired: 1,
        users: [8, 9],
        groups: [7],
      };
      axiosMock.onPut(mocks.state.projectPath).replyOnce(HTTP_STATUS_OK);

      return testAction(
        actions.putFallbackRule,
        payload,
        state,
        [],
        [
          {
            type: 'fetchRules',
          },
        ],
        () => {
          expect(axiosMock.history.put[0].data).toBe('{"fallback_approvals_required":1}');
        },
      );
    });

    it('creates an alert error if the request is not successful', async () => {
      axiosMock.onPut(mocks.state.projectPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      await actions.putFallbackRule({ rootState: state, dispatch: () => {} }, {});

      expect(createAlert).toHaveBeenNthCalledWith(1, { message: expect.any(String) });
    });
  });
});
