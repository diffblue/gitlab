import * as Sentry from '@sentry/browser';
import MockAdapter from 'axios-mock-adapter';
import actionsFactory from 'ee/approvals/stores/modules/approval_settings/actions';
import * as types from 'ee/approvals/stores/modules/approval_settings/mutation_types';
import getInitialState from 'ee/approvals/stores/modules/approval_settings/state';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('EE approvals group settings module actions', () => {
  let state;
  let mock;

  const actions = actionsFactory((data) => data);
  const approvalSettingsPath = 'groups/22/merge_request_approval_setting';

  beforeEach(() => {
    state = getInitialState();
    mock = new MockAdapter(axios);
    jest.spyOn(Sentry, 'captureException');
  });

  afterEach(() => {
    mock.restore();
  });

  describe('fetchSettings', () => {
    describe('on success', () => {
      it('dispatches the request and updates payload', () => {
        const data = { allow_author_approval: true };
        mock.onGet(approvalSettingsPath).replyOnce(HTTP_STATUS_OK, data);

        return testAction(
          actions.fetchSettings,
          approvalSettingsPath,
          state,
          [
            { type: types.REQUEST_SETTINGS },
            { type: types.RECEIVE_SETTINGS_SUCCESS, payload: data },
          ],
          [],
        );
      });
    });

    describe('on error', () => {
      it('dispatches the request, updates payload and sets error message', () => {
        const data = { message: 'Internal Server Error' };
        mock.onGet(approvalSettingsPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, data);

        return testAction(
          actions.fetchSettings,
          approvalSettingsPath,
          state,
          [{ type: types.REQUEST_SETTINGS }, { type: types.RECEIVE_SETTINGS_ERROR }],
          [],
        ).then(() => {
          expect(Sentry.captureException.mock.calls[0][0]).toBe(data.message);
        });
      });
    });
  });

  describe.each`
    httpMethod | onMethod
    ${'put'}   | ${'onPut'}
    ${'post'}  | ${'onPost'}
  `('updateSetting with $httpMethod', ({ httpMethod, onMethod }) => {
    let actionsWithMethod;

    beforeEach(() => {
      state = {
        settings: {},
      };
      actionsWithMethod = actionsFactory((data) => data, httpMethod);
    });

    describe('on success', () => {
      it('dispatches the request and updates payload', () => {
        const data = {
          allow_author_approval: { value: true },
          allow_committer_approval: { value: true },
          allow_overrides_to_approver_list_per_merge_request: { value: true },
          require_password_to_approve: { value: true },
          retain_approvals_on_push: { value: true },
        };
        mock[onMethod](approvalSettingsPath).replyOnce(HTTP_STATUS_OK, data);

        return testAction(
          actionsWithMethod.updateSettings,
          approvalSettingsPath,
          state,
          [
            { type: types.REQUEST_UPDATE_SETTINGS },
            { type: types.UPDATE_SETTINGS_SUCCESS, payload: data },
          ],
          [],
        );
      });
    });

    describe('on error', () => {
      it('dispatches the request, updates payload and sets error message', () => {
        const data = { message: 'Internal Server Error' };
        mock[onMethod](approvalSettingsPath).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, data);

        return testAction(
          actionsWithMethod.updateSettings,
          approvalSettingsPath,
          state,
          [{ type: types.REQUEST_UPDATE_SETTINGS }, { type: types.UPDATE_SETTINGS_ERROR }],
          [],
        ).then(() => {
          expect(Sentry.captureException.mock.calls[0][0]).toBe(data.message);
        });
      });
    });
  });

  describe('dismissErrorMessage', () => {
    it('commits DISMISS_ERROR_MESSAGE', () => {
      return testAction(
        actions.dismissErrorMessage,
        {},
        state,
        [{ type: types.DISMISS_ERROR_MESSAGE }],
        [],
      );
    });
  });

  describe.each`
    action                             | type
    ${'setPreventAuthorApproval'}      | ${types.SET_PREVENT_AUTHOR_APPROVAL}
    ${'setPreventCommittersApproval'}  | ${types.SET_PREVENT_COMMITTERS_APPROVAL}
    ${'setPreventMrApprovalRuleEdit'}  | ${types.SET_PREVENT_MR_APPROVAL_RULE_EDIT}
    ${'setRemoveApprovalsOnPush'}      | ${types.SET_REMOVE_APPROVALS_ON_PUSH}
    ${'setSelectiveCodeOwnerRemovals'} | ${types.SET_SELECTIVE_CODE_OWNER_REMOVALS}
    ${'setRequireUserPassword'}        | ${types.SET_REQUIRE_USER_PASSWORD}
  `('$action', ({ action, type }) => {
    it(`commits ${type}`, () => {
      return testAction(actions[action], true, state, [{ type, payload: true }], []);
    });
  });
});
