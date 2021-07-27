import * as Sentry from '@sentry/browser';
import MockAdapter from 'axios-mock-adapter';
import actionsFactory from 'ee/approvals/stores/modules/approval_settings/actions';
import * as types from 'ee/approvals/stores/modules/approval_settings/mutation_types';
import getInitialState from 'ee/approvals/stores/modules/approval_settings/state';
import testAction from 'helpers/vuex_action_helper';
import axios from '~/lib/utils/axios_utils';
import httpStatus from '~/lib/utils/http_status';

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
        mock.onGet(approvalSettingsPath).replyOnce(httpStatus.OK, data);

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
        mock.onGet(approvalSettingsPath).replyOnce(httpStatus.INTERNAL_SERVER_ERROR, data);

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

  describe('updateSettings', () => {
    beforeEach(() => {
      state = {
        settings: {},
      };
    });

    describe('on success', () => {
      it('dispatches the request and updates payload', () => {
        const data = {
          allow_author_approval: true,
          allow_committer_approval: true,
          allow_overrides_to_approver_list_per_merge_request: true,
          require_password_to_approve: true,
          retain_approvals_on_push: true,
        };
        mock.onPut(approvalSettingsPath).replyOnce(httpStatus.OK, data);

        return testAction(
          actions.updateSettings,
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
        mock.onPut(approvalSettingsPath).replyOnce(httpStatus.INTERNAL_SERVER_ERROR, data);

        return testAction(
          actions.updateSettings,
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

  describe('dismissSuccessMessage', () => {
    it('commits DISMISS_SUCCESS_MESSAGE', () => {
      return testAction(
        actions.dismissSuccessMessage,
        {},
        state,
        [{ type: types.DISMISS_SUCCESS_MESSAGE }],
        [],
      );
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
    action                            | type                                       | prop
    ${'setPreventAuthorApproval'}     | ${types.SET_PREVENT_AUTHOR_APPROVAL}       | ${'preventAuthorApproval'}
    ${'setPreventCommittersApproval'} | ${types.SET_PREVENT_COMMITTERS_APPROVAL}   | ${'preventCommittersApproval'}
    ${'setPreventMrApprovalRuleEdit'} | ${types.SET_PREVENT_MR_APPROVAL_RULE_EDIT} | ${'preventMrApprovalRuleEdit'}
    ${'setRemoveApprovalsOnPush'}     | ${types.SET_REMOVE_APPROVALS_ON_PUSH}      | ${'removeApprovalsOnPush'}
    ${'setRequireUserPassword'}       | ${types.SET_REQUIRE_USER_PASSWORD}         | ${'requireUserPassword'}
  `('$action', ({ action, type, prop }) => {
    it(`commits ${type}`, () => {
      const payload = { [prop]: true };

      return testAction(actions[action], payload, state, [{ type, payload: true }], []);
    });
  });
});
