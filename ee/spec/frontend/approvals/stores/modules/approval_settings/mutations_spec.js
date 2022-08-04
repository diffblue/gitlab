import { APPROVAL_SETTINGS_I18N } from 'ee/approvals/constants';
import mutationsFactory from 'ee/approvals/stores/modules/approval_settings/mutations';
import getInitialState from 'ee/approvals/stores/modules/approval_settings/state';

describe('Group settings store mutations', () => {
  let state;

  const mapperFn = jest.fn((data) => data);
  const mutations = mutationsFactory(mapperFn);
  const settings = {
    preventAuthorApproval: { value: false },
    preventCommittersApproval: { value: false },
    preventMrApprovalRuleEdit: { value: false },
    requireUserPassword: { value: false },
    removeApprovalsOnPush: { value: false },
    selectiveCodeOwnerRemovals: { value: false },
  };

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
      mutations.RECEIVE_SETTINGS_SUCCESS(state, settings);

      expect(mapperFn).toHaveBeenCalledWith(settings);
      expect(state.settings).toStrictEqual(settings);
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
      expect(state.errorMessage).toBe('');
    });
  });

  describe('UPDATE_SETTINGS_SUCCESS', () => {
    it('updates settings', () => {
      mutations.UPDATE_SETTINGS_SUCCESS(state, settings);

      expect(mapperFn).toHaveBeenCalledWith(settings);
      expect(state.settings).toStrictEqual(settings);
      expect(state.isLoading).toBe(false);
    });
  });

  describe('UPDATE_SETTINGS_ERROR', () => {
    it('sets loading state', () => {
      mutations.UPDATE_SETTINGS_ERROR(state);

      expect(state.isLoading).toBe(false);
      expect(state.errorMessage).toBe(APPROVAL_SETTINGS_I18N.savingErrorMessage);
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
    ${'SET_SELECTIVE_CODE_OWNER_REMOVALS'} | ${'selectiveCodeOwnerRemovals'}
    ${'SET_REQUIRE_USER_PASSWORD'}         | ${'requireUserPassword'}
  `('$mutation', ({ mutation, prop }) => {
    beforeEach(() => {
      mutations.RECEIVE_SETTINGS_SUCCESS(state, settings);
    });

    it(`sets the ${prop}`, () => {
      mutations[mutation](state, true);

      expect(state.settings[prop].value).toBe(true);
    });
  });
});
