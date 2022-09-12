import { DEFAULT_TIMEOUT, DEFAULT_ALLOWED_IP } from 'ee/geo_settings/constants';
import * as types from 'ee/geo_settings/store/mutation_types';
import mutations from 'ee/geo_settings/store/mutations';
import createState from 'ee/geo_settings/store/state';
import { MOCK_BASIC_SETTINGS_DATA } from '../mock_data';

describe('GeoSettings Store Mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe.each`
    mutation                                   | data                        | loadingBefore | loadingAfter
    ${types.REQUEST_GEO_SETTINGS}              | ${null}                     | ${false}      | ${true}
    ${types.RECEIVE_GEO_SETTINGS_SUCCESS}      | ${MOCK_BASIC_SETTINGS_DATA} | ${true}       | ${false}
    ${types.RECEIVE_GEO_SETTINGS_ERROR}        | ${null}                     | ${true}       | ${false}
    ${types.REQUEST_UPDATE_GEO_SETTINGS}       | ${null}                     | ${false}      | ${true}
    ${types.RECEIVE_UPDATE_GEO_SETTINGS_ERROR} | ${null}                     | ${true}       | ${false}
  `(`Loading Mutations:`, ({ mutation, data, loadingBefore, loadingAfter }) => {
    describe(`${mutation}`, () => {
      it(`sets isLoading to ${loadingAfter}`, () => {
        state.isLoading = loadingBefore;

        mutations[mutation](state, data);
        expect(state.isLoading).toEqual(loadingAfter);
      });
    });
  });

  describe('RECEIVE_GEO_SETTINGS_SUCCESS', () => {
    it('sets timeout and allowedIp array with data', () => {
      mutations[types.RECEIVE_GEO_SETTINGS_SUCCESS](state, MOCK_BASIC_SETTINGS_DATA);

      expect(state.timeout).toBe(MOCK_BASIC_SETTINGS_DATA.timeout);
      expect(state.allowedIp).toBe(MOCK_BASIC_SETTINGS_DATA.allowedIp);
    });
  });

  describe('RECEIVE_GEO_SETTINGS_ERROR', () => {
    beforeEach(() => {
      state.timeout = MOCK_BASIC_SETTINGS_DATA.timeout;
      state.allowedIp = MOCK_BASIC_SETTINGS_DATA.allowedIp;
    });

    it('resets timeout and allowedIp array', () => {
      mutations[types.RECEIVE_GEO_SETTINGS_ERROR](state);

      expect(state.timeout).toBe(DEFAULT_TIMEOUT);
      expect(state.allowedIp).toBe(DEFAULT_ALLOWED_IP);
    });
  });

  describe('RECEIVE_UPDATE_GEO_SETTINGS_SUCCESS', () => {
    it('sets timeout and allowedIp array with data', () => {
      mutations[types.RECEIVE_UPDATE_GEO_SETTINGS_SUCCESS](state, MOCK_BASIC_SETTINGS_DATA);

      expect(state.timeout).toBe(MOCK_BASIC_SETTINGS_DATA.timeout);
      expect(state.allowedIp).toBe(MOCK_BASIC_SETTINGS_DATA.allowedIp);
    });
  });

  describe('RECEIVE_UPDATE_GEO_SETTINGS_ERROR', () => {
    beforeEach(() => {
      state.timeout = MOCK_BASIC_SETTINGS_DATA.timeout;
      state.allowedIp = MOCK_BASIC_SETTINGS_DATA.allowedIp;
    });

    it('resets timeout and allowedIp array', () => {
      mutations[types.RECEIVE_UPDATE_GEO_SETTINGS_ERROR](state);

      expect(state.timeout).toBe(DEFAULT_TIMEOUT);
      expect(state.allowedIp).toBe(DEFAULT_ALLOWED_IP);
    });
  });

  describe('SET_TIMEOUT', () => {
    it('sets error for field', () => {
      mutations[types.SET_TIMEOUT](state, 1);
      expect(state.timeout).toBe(1);
    });
  });

  describe('SET_ALLOWED_IP', () => {
    it('sets error for field', () => {
      mutations[types.SET_ALLOWED_IP](state, '0.0.0.0');
      expect(state.allowedIp).toBe('0.0.0.0');
    });
  });

  describe('SET_FORM_ERROR', () => {
    it('sets error for field', () => {
      mutations[types.SET_FORM_ERROR](state, { key: 'timeout', error: 'error' });
      expect(state.formErrors.timeout).toBe('error');
    });
  });
});
