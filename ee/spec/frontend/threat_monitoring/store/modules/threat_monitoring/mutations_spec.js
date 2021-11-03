import * as types from 'ee/threat_monitoring/store/modules/threat_monitoring/mutation_types';
import mutations from 'ee/threat_monitoring/store/modules/threat_monitoring/mutations';

describe('Threat Monitoring mutations', () => {
  let state;

  beforeEach(() => {
    state = {
      currentEnvironmentId: -1,
    };
  });

  describe(types.SET_ENDPOINT, () => {
    it('sets the endpoints', () => {
      mutations[types.SET_ENDPOINT](state, 'envs');
      expect(state.environmentsEndpoint).toEqual('envs');
    });
  });

  describe(types.REQUEST_ENVIRONMENTS, () => {
    beforeEach(() => {
      mutations[types.REQUEST_ENVIRONMENTS](state);
    });

    it('sets isLoadingEnvironments to true', () => {
      expect(state.isLoadingEnvironments).toBe(true);
    });

    it('sets errorLoadingEnvironments to false', () => {
      expect(state.errorLoadingEnvironments).toBe(false);
    });
  });

  describe(types.RECEIVE_ENVIRONMENTS_SUCCESS, () => {
    let environments;

    beforeEach(() => {
      environments = [{ id: 1, name: 'production' }];
      mutations[types.RECEIVE_ENVIRONMENTS_SUCCESS](state, { environments, nextPage: '' });
    });

    it('sets environments', () => {
      expect(state.environments).toBe(environments);
    });

    it('sets isLoadingEnvironments to false', () => {
      expect(state.isLoadingEnvironments).toBe(false);
    });

    it('sets errorLoadingEnvironments to false', () => {
      expect(state.errorLoadingEnvironments).toBe(false);
    });

    it('sets currentEnvironmentId to 1', () => {
      expect(state.currentEnvironmentId).toEqual(1);
    });

    describe('without environments', () => {
      beforeEach(() => {
        state.currentEnvironmentId = 1;
        mutations[types.RECEIVE_ENVIRONMENTS_SUCCESS](state, { environments: [], nextPage: '' });
      });

      it('does not update currentEnvironmentId', () => {
        expect(state.currentEnvironmentId).toBe(1);
      });
    });

    describe('with currentEnvironmentId set', () => {
      beforeEach(() => {
        state.currentEnvironmentId = 1;
        environments = [{ id: 2, name: 'production' }];
        mutations[types.RECEIVE_ENVIRONMENTS_SUCCESS](state, { environments, nextPage: '' });
      });

      it('does not update currentEnvironmentId', () => {
        expect(state.currentEnvironmentId).toBe(1);
      });
    });
  });

  describe(types.RECEIVE_ENVIRONMENTS_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_ENVIRONMENTS_ERROR](state);
    });

    it('sets isLoadingEnvironments to false', () => {
      expect(state.isLoadingEnvironments).toBe(false);
    });

    it('sets errorLoadingEnvironments to true', () => {
      expect(state.errorLoadingEnvironments).toBe(true);
    });
  });

  describe(types.SET_CURRENT_ENVIRONMENT_ID, () => {
    const environmentId = 3;

    beforeEach(() => {
      mutations[types.SET_CURRENT_ENVIRONMENT_ID](state, environmentId);
    });

    it('sets currentEnvironmentId and allEnvironments', () => {
      expect(state.currentEnvironmentId).toBe(environmentId);
      expect(state.allEnvironments).toBe(false);
    });
  });

  describe(types.SET_CURRENT_TIME_WINDOW, () => {
    const timeWindow = 'foo';

    beforeEach(() => {
      mutations[types.SET_CURRENT_TIME_WINDOW](state, timeWindow);
    });

    it('sets currentTimeWindow', () => {
      expect(state.currentTimeWindow).toBe(timeWindow);
    });
  });

  describe(types.SET_ALL_ENVIRONMENTS, () => {
    beforeEach(() => {
      mutations[types.SET_ALL_ENVIRONMENTS](state);
    });

    it('sets allEnvironments', () => {
      expect(state.allEnvironments).toBe(true);
    });
  });
});
