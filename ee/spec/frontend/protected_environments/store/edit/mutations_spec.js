import { mutations } from 'ee/protected_environments/store/edit/mutations';
import * as types from 'ee/protected_environments/store/edit/mutation_types';
import { state } from 'ee/protected_environments/store/edit/state';

describe('ee/protected_environments/store/edit/mutations', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state({ projectId: '8' });
  });

  describe(types.REQUEST_PROTECTED_ENVIRONMENTS, () => {
    it('sets loading to true', () => {
      mutations[types.REQUEST_PROTECTED_ENVIRONMENTS](mockedState);

      expect(mockedState.loading).toBe(true);
    });
  });

  describe(types.RECEIVE_PROTECTED_ENVIRONMENTS_SUCCESS, () => {
    const environments = [{ name: 'staging' }];

    beforeEach(() => {
      mutations[types.RECEIVE_PROTECTED_ENVIRONMENTS_SUCCESS](mockedState, environments);
    });

    it('sets loading to false', () => {
      expect(mockedState.loading).toBe(false);
    });

    it('saves the environments', () => {
      expect(mockedState.protectedEnvironments).toEqual(environments);
    });
  });

  describe(types.RECEIVE_PROTECTED_ENVIRONMENTS_ERROR, () => {
    it('sets loading to false', () => {
      mutations[types.RECEIVE_PROTECTED_ENVIRONMENTS_ERROR](mockedState);

      expect(mockedState.loading).toBe(false);
    });
  });

  describe(types.REQUEST_MEMBERS, () => {
    it('sets loading to true', () => {
      mutations[types.REQUEST_MEMBERS](mockedState);

      expect(mockedState.loading).toBe(true);
    });
  });

  describe(types.RECEIVE_MEMBERS_FINISH, () => {
    it('sets loading to false', () => {
      mutations[types.RECEIVE_MEMBERS_FINISH](mockedState);
      expect(mockedState.loading).toBe(false);
    });
  });

  describe(types.RECEIVE_MEMBERS_ERROR, () => {
    it('sets loading to false', () => {
      mutations[types.RECEIVE_MEMBERS_ERROR](mockedState);
      expect(mockedState.loading).toBe(false);
    });
  });

  describe(types.RECEIVE_MEMBER_SUCCESS, () => {
    it('sets loading to false', () => {
      const rule = { user_id: 0, id: 1 };
      const users = [{ name: 'root', id: 0 }];
      mutations[types.RECEIVE_MEMBER_SUCCESS](mockedState, { rule, users });

      expect(mockedState.loading).toBe(false);
    });
  });
});
