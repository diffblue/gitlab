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

    it('sets entries to save new rules', () => {
      expect(mockedState.newDeployAccessLevelsForEnvironment).toEqual({
        staging: [],
      });
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

  describe(types.REQUEST_UPDATE_PROTECTED_ENVIRONMENT, () => {
    it('sets loading to true', () => {
      mutations[types.REQUEST_UPDATE_PROTECTED_ENVIRONMENT](mockedState);

      expect(mockedState.loading).toBe(true);
    });
  });

  describe(types.RECEIVE_UPDATE_PROTECTED_ENVIRONMENT_SUCCESS, () => {
    const environment = { name: 'staging' };
    const updatedEnvironment = { ...environment, deploy_access_levels: [] };

    beforeEach(() => {
      mockedState.protectedEnvironments = [environment];
      mutations[types.RECEIVE_UPDATE_PROTECTED_ENVIRONMENT_SUCCESS](
        mockedState,
        updatedEnvironment,
      );
    });

    it('sets loading to false', () => {
      expect(mockedState.loading).toBe(false);
    });

    it('updates the saved environment', () => {
      expect(mockedState.protectedEnvironments).toEqual([updatedEnvironment]);
    });

    it('clears the new rules', () => {
      expect(mockedState.newDeployAccessLevelsForEnvironment).toEqual({
        staging: [],
      });
    });
  });

  describe(types.RECEIVE_UPDATE_PROTECTED_ENVIRONMENT_ERROR, () => {
    it('sets loading to false', () => {
      mutations[types.RECEIVE_UPDATE_PROTECTED_ENVIRONMENT_ERROR](mockedState);
      expect(mockedState.loading).toBe(false);
    });
  });

  describe(types.SET_RULE, () => {
    it('saves the new rules to put to an environment', () => {
      const environment = { name: 'staging' };
      const rules = [{ user_id: 5 }];

      mutations[types.SET_RULE](mockedState, { environment, rules });

      expect(mockedState.newDeployAccessLevelsForEnvironment[environment.name]).toEqual(rules);
    });
  });

  describe(types.DELETE_PROTECTED_ENVIRONMENT_SUCCESS, () => {
    const environment = { name: 'staging' };

    beforeEach(() => {
      mockedState.protectedEnvironments = [environment];
      mutations[types.DELETE_PROTECTED_ENVIRONMENT_SUCCESS](mockedState, environment);
    });

    it('sets loading to false', () => {
      expect(mockedState.loading).toBe(false);
    });

    it('updates the saved environment', () => {
      expect(mockedState.protectedEnvironments).toEqual([]);
    });

    it('clears the new rules', () => {
      expect(mockedState.newDeployAccessLevelsForEnvironment).toEqual({
        staging: [],
      });
    });
  });
});
