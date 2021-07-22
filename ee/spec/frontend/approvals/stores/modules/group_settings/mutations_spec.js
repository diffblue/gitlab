import { APPROVAL_SETTINGS_I18N } from 'ee/approvals/constants';
import mutations from 'ee/approvals/stores/modules/group_settings/mutations';
import getInitialState from 'ee/approvals/stores/modules/group_settings/state';

describe('Group settings store mutations', () => {
  let state;

  beforeEach(() => {
    state = getInitialState();
  });

  describe('REQUEST_SETTINGS', () => {
    it('sets loading state', () => {
      mutations.REQUEST_SETTINGS(state);

      expect(state.isLoading).toBe(true);
      expect(state.errorMessage).toBe('');
    });
  });

  describe('RECEIVE_SETTINGS_SUCCESS', () => {
    it('updates settings', () => {
      mutations.RECEIVE_SETTINGS_SUCCESS(state, {
        allow_author_approval: true,
        allow_committer_approval: true,
        allow_overrides_to_approver_list_per_merge_request: true,
        require_password_to_approve: true,
        retain_approvals_on_push: true,
      });

      expect(state.settings.preventAuthorApproval).toBe(false);
      expect(state.settings.preventCommittersApproval).toBe(false);
      expect(state.settings.preventMrApprovalRuleEdit).toBe(false);
      expect(state.settings.requireUserPassword).toBe(true);
      expect(state.settings.removeApprovalsOnPush).toBe(false);
      expect(state.isLoading).toBe(false);
    });
  });

  describe('RECEIVE_SETTINGS_ERROR', () => {
    it('sets loading state', () => {
      mutations.RECEIVE_SETTINGS_ERROR(state);

      expect(state.isLoading).toBe(false);
      expect(state.errorMessage).toBe(APPROVAL_SETTINGS_I18N.loadingErrorMessage);
    });
  });

  describe('REQUEST_UPDATE_SETTINGS', () => {
    it('sets loading state', () => {
      mutations.REQUEST_UPDATE_SETTINGS(state);

      expect(state.isLoading).toBe(true);
      expect(state.isUpdated).toBe(false);
      expect(state.errorMessage).toBe('');
    });
  });

  describe('UPDATE_SETTINGS_SUCCESS', () => {
    it('updates settings', () => {
      mutations.UPDATE_SETTINGS_SUCCESS(state, {
        allow_author_approval: true,
        allow_overrides_to_approver_list_per_merge_request: true,
        require_password_to_approve: true,
        retain_approvals_on_push: true,
      });

      expect(state.settings.preventAuthorApproval).toBe(false);
      expect(state.settings.preventMrApprovalRuleEdit).toBe(false);
      expect(state.settings.requireUserPassword).toBe(true);
      expect(state.settings.removeApprovalsOnPush).toBe(false);
      expect(state.isLoading).toBe(false);
      expect(state.isUpdated).toBe(true);
    });
  });

  describe('UPDATE_SETTINGS_ERROR', () => {
    it('sets loading state', () => {
      mutations.UPDATE_SETTINGS_ERROR(state);

      expect(state.isLoading).toBe(false);
      expect(state.errorMessage).toBe(APPROVAL_SETTINGS_I18N.savingErrorMessage);
    });
  });

  describe('DISMISS_SUCCESS_MESSAGE', () => {
    it('resets isUpdated', () => {
      mutations.DISMISS_SUCCESS_MESSAGE(state);

      expect(state.isUpdated).toBe(false);
    });
  });

  describe('DISMISS_ERROR_MESSAGE', () => {
    it('resets errorMessage', () => {
      mutations.DISMISS_ERROR_MESSAGE(state);

      expect(state.errorMessage).toBe('');
    });
  });

  describe.each`
    mutation                               | prop
    ${'SET_PREVENT_AUTHOR_APPROVAL'}       | ${'preventAuthorApproval'}
    ${'SET_PREVENT_COMMITTERS_APPROVAL'}   | ${'preventCommittersApproval'}
    ${'SET_PREVENT_MR_APPROVAL_RULE_EDIT'} | ${'preventMrApprovalRuleEdit'}
    ${'SET_REMOVE_APPROVALS_ON_PUSH'}      | ${'removeApprovalsOnPush'}
    ${'SET_REQUIRE_USER_PASSWORD'}         | ${'requireUserPassword'}
  `('$mutation', ({ mutation, prop }) => {
    it(`sets the ${prop}`, () => {
      mutations[mutation](state, true);

      expect(state.settings[prop]).toBe(true);
    });
  });
});
