import * as types from 'ee/geo_site_form/store/mutation_types';
import mutations from 'ee/geo_site_form/store/mutations';
import createState from 'ee/geo_site_form/store/state';
import { MOCK_SYNC_NAMESPACES } from '../mock_data';

describe('GeoSiteForm Store Mutations', () => {
  let state;
  beforeEach(() => {
    state = createState();
  });

  describe.each`
    mutation                                 | loadingBefore | loadingAfter
    ${types.REQUEST_SYNC_NAMESPACES}         | ${false}      | ${true}
    ${types.RECEIVE_SYNC_NAMESPACES_SUCCESS} | ${true}       | ${false}
    ${types.RECEIVE_SYNC_NAMESPACES_ERROR}   | ${true}       | ${false}
    ${types.REQUEST_SAVE_GEO_SITE}           | ${false}      | ${true}
    ${types.RECEIVE_SAVE_GEO_SITE_COMPLETE}  | ${true}       | ${false}
    ${types.RECEIVE_SAVE_GEO_SITE_COMPLETE}  | ${true}       | ${false}
  `(`Loading Mutations:`, ({ mutation, loadingBefore, loadingAfter }) => {
    describe(`${mutation}`, () => {
      it(`sets isLoading to ${loadingAfter}`, () => {
        state.isLoading = loadingBefore;

        mutations[mutation](state);
        expect(state.isLoading).toEqual(loadingAfter);
      });
    });
  });

  describe('RECEIVE_SYNC_NAMESPACES_SUCCESS', () => {
    it('sets synchronizationNamespaces array with namespace data', () => {
      mutations[types.RECEIVE_SYNC_NAMESPACES_SUCCESS](state, MOCK_SYNC_NAMESPACES);
      expect(state.synchronizationNamespaces).toBe(MOCK_SYNC_NAMESPACES);
    });
  });

  describe('RECEIVE_SYNC_NAMESPACES_ERROR', () => {
    it('resets synchronizationNamespaces array', () => {
      state.synchronizationNamespaces = MOCK_SYNC_NAMESPACES;

      mutations[types.RECEIVE_SYNC_NAMESPACES_ERROR](state);
      expect(state.synchronizationNamespaces).toEqual([]);
    });
  });

  describe('SET_ERROR', () => {
    it('sets error for field', () => {
      mutations[types.SET_ERROR](state, { key: 'name', error: 'error' });
      expect(state.formErrors.name).toBe('error');
    });
  });
});
