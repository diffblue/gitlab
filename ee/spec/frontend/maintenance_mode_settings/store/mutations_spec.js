import {
  DEFAULT_MAINTENANCE_ENABLED,
  DEFAULT_BANNER_MESSAGE,
} from 'ee/maintenance_mode_settings/constants';
import * as types from 'ee/maintenance_mode_settings/store/mutation_types';
import mutations from 'ee/maintenance_mode_settings/store/mutations';
import { createState } from 'ee/maintenance_mode_settings/store/state';
import { MOCK_BASIC_SETTINGS_DATA } from '../mock_data';

describe('MaintenanceModeSettings Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = createState({
      maintenanceEnabled: DEFAULT_MAINTENANCE_ENABLED,
      bannerMessage: DEFAULT_BANNER_MESSAGE,
    });
  });

  afterEach(() => {
    state = null;
  });

  describe.each`
    mutation                                                | data    | loadingBefore | loadingAfter
    ${types.REQUEST_UPDATE_MAINTENANCE_MODE_SETTINGS}       | ${null} | ${false}      | ${true}
    ${types.REQUEST_UPDATE_MAINTENANCE_MODE_SETTINGS}       | ${null} | ${false}      | ${true}
    ${types.RECEIVE_UPDATE_MAINTENANCE_MODE_SETTINGS_ERROR} | ${null} | ${true}       | ${false}
  `(`Loading Mutations:`, ({ mutation, data, loadingBefore, loadingAfter }) => {
    describe(`${mutation}`, () => {
      it(`sets loading to ${loadingAfter}`, () => {
        state.loading = loadingBefore;

        mutations[mutation](state, data);
        expect(state.loading).toBe(loadingAfter);
      });
    });
  });

  describe('RECEIVE_UPDATE_MAINTENANCE_MODE_SETTINGS_SUCCESS', () => {
    it('sets maintenanceEnabled and bannerMessage array with data', () => {
      mutations[types.RECEIVE_UPDATE_MAINTENANCE_MODE_SETTINGS_SUCCESS](
        state,
        MOCK_BASIC_SETTINGS_DATA,
      );

      expect(state.maintenanceEnabled).toBe(MOCK_BASIC_SETTINGS_DATA.maintenanceEnabled);
      expect(state.bannerMessage).toBe(MOCK_BASIC_SETTINGS_DATA.bannerMessage);
    });
  });

  describe('RECEIVE_UPDATE_MAINTENANCE_MODE_SETTINGS_ERROR', () => {
    beforeEach(() => {
      state.maintenanceEnabled = MOCK_BASIC_SETTINGS_DATA.maintenanceEnabled;
      state.bannerMessage = MOCK_BASIC_SETTINGS_DATA.bannerMessage;
    });

    it('resets maintenanceEnabled and bannerMessage array', () => {
      mutations[types.RECEIVE_UPDATE_MAINTENANCE_MODE_SETTINGS_ERROR](state);

      expect(state.maintenanceEnabled).toBe(DEFAULT_MAINTENANCE_ENABLED);
      expect(state.bannerMessage).toBe(DEFAULT_BANNER_MESSAGE);
    });
  });

  describe('SET_MAINTENANCE_ENABLED', () => {
    it('sets data for field', () => {
      mutations[types.SET_MAINTENANCE_ENABLED](state, true);
      expect(state.maintenanceEnabled).toBe(true);
    });
  });

  describe('SET_BANNER_MESSAGE', () => {
    it('sets data for field', () => {
      mutations[types.SET_BANNER_MESSAGE](state, 'test');
      expect(state.bannerMessage).toBe('test');
    });
  });
});
