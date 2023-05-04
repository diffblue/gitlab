import * as types from 'ee/epic/store/mutation_types';
import mutations from 'ee/epic/store/mutations';

import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('Epic Store Mutations', () => {
  describe('SET_EPIC_META', () => {
    it('Should add Epic meta to state', () => {
      const state = {};
      mutations[types.SET_EPIC_META](state, mockEpicMeta);

      expect(state).toEqual(mockEpicMeta);
    });
  });

  describe('SET_EPIC_DATA', () => {
    it('Should add Epic data to state', () => {
      const state = {};
      mutations[types.SET_EPIC_DATA](state, mockEpicData);

      expect(state).toEqual(mockEpicData);
    });
  });

  describe('REQUEST_EPIC_STATUS_CHANGE', () => {
    it('Should set `epicStatusChangeInProgress` flag on state as `true`', () => {
      const state = {};
      mutations[types.REQUEST_EPIC_STATUS_CHANGE](state);

      expect(state.epicStatusChangeInProgress).toBe(true);
    });
  });

  describe('REQUEST_EPIC_STATUS_CHANGE_SUCCESS', () => {
    it('Should set `epicStatusChangeInProgress` flag on state as `false` and update Epic `state`', () => {
      const state = {
        state: 'opened',
      };
      mutations[types.REQUEST_EPIC_STATUS_CHANGE_SUCCESS](state, { state: 'closed' });

      expect(state.epicStatusChangeInProgress).toBe(false);
      expect(state.state).toBe('closed');
    });
  });

  describe('REQUEST_EPIC_STATUS_CHANGE_FAILURE', () => {
    it('Should set `epicStatusChangeInProgress` flag on state as `false`', () => {
      const state = {};
      mutations[types.REQUEST_EPIC_STATUS_CHANGE_FAILURE](state);

      expect(state.epicStatusChangeInProgress).toBe(false);
    });
  });

  describe('TOGGLE_SIDEBAR', () => {
    it('Should set `sidebarCollapsed` flag on state with value of provided `sidebarCollapsed` param', () => {
      const state = {};
      const sidebarCollapsed = true;

      mutations[types.TOGGLE_SIDEBAR](state, sidebarCollapsed);

      expect(state.sidebarCollapsed).toBe(sidebarCollapsed);
    });
  });

  describe('SET_EPIC_CREATE_TITLE', () => {
    it('Should set `newEpicTitle` prop on state as with the value of provided `newEpicTitle` param', () => {
      const state = {
        newEpicTitle: '',
      };

      mutations[types.SET_EPIC_CREATE_TITLE](state, {
        newEpicTitle: 'foobar',
      });

      expect(state.newEpicTitle).toBe('foobar');
    });
  });

  describe('SET_EPIC_CREATE_CONFIDENTIAL', () => {
    it('Should set `newEpicConfidential` prop on state as with the value of provided `newEpicConfidential` param', () => {
      const state = {
        newEpicConfidential: true,
      };

      mutations[types.SET_EPIC_CREATE_CONFIDENTIAL](state, {
        newEpicConfidential: true,
      });

      expect(state.newEpicConfidential).toBe(true);
    });
  });

  describe('REQUEST_EPIC_CREATE', () => {
    it('Should set `epicCreateInProgress` flag on state as `true`', () => {
      const state = {
        epicCreateInProgress: false,
      };

      mutations[types.REQUEST_EPIC_CREATE](state);

      expect(state.epicCreateInProgress).toBe(true);
    });
  });

  describe('REQUEST_EPIC_CREATE_FAILURE', () => {
    it('Should set `epicCreateInProgress` flag on state as `false`', () => {
      const state = {
        epicCreateInProgress: true,
      };

      mutations[types.REQUEST_EPIC_CREATE_FAILURE](state);

      expect(state.epicCreateInProgress).toBe(false);
    });
  });

  describe('SET_EPIC_CONFIDENTIAL', () => {
    it('Should set `confidential` flag on state to `true`', () => {
      const state = {
        confidential: false,
      };

      const confidential = true;

      mutations[types.SET_EPIC_CONFIDENTIAL](state, confidential);

      expect(state.confidential).toBe(true);
    });
  });
});
