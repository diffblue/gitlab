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
});
