import * as types from 'ee/geo_sites/store/mutation_types';
import mutations from 'ee/geo_sites/store/mutations';
import createState from 'ee/geo_sites/store/state';
import { MOCK_SORTED_REPLICABLE_TYPES, MOCK_SITES } from '../mock_data';

describe('GeoSites Store Mutations', () => {
  let state;
  beforeEach(() => {
    state = createState({
      replicableTypes: MOCK_SORTED_REPLICABLE_TYPES,
    });
  });

  describe('REQUEST_SITES', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_SITES](state);

      expect(state.isLoading).toBe(true);
    });
  });

  describe('RECEIVE_SITES_SUCCESS', () => {
    beforeEach(() => {
      state.isLoading = true;
    });

    it('sets sites and ends loading', () => {
      mutations[types.RECEIVE_SITES_SUCCESS](state, MOCK_SITES);

      expect(state.isLoading).toBe(false);
      expect(state.sites).toEqual(MOCK_SITES);
    });
  });

  describe('RECEIVE_SITES_ERROR', () => {
    beforeEach(() => {
      state.isLoading = true;
      state.sites = MOCK_SITES;
    });

    it('resets state', () => {
      mutations[types.RECEIVE_SITES_ERROR](state);

      expect(state.isLoading).toBe(false);
      expect(state.sites).toEqual([]);
    });
  });

  describe('STAGE_SITE_REMOVAL', () => {
    it('sets siteToBeRemoved to site id', () => {
      mutations[types.STAGE_SITE_REMOVAL](state, 1);

      expect(state.siteToBeRemoved).toBe(1);
    });
  });

  describe('UNSTAGE_SITE_REMOVAL', () => {
    beforeEach(() => {
      state.siteToBeRemoved = 1;
    });

    it('sets siteToBeRemoved to null', () => {
      mutations[types.UNSTAGE_SITE_REMOVAL](state);

      expect(state.siteToBeRemoved).toBe(null);
    });
  });

  describe('REQUEST_SITE_REMOVAL', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_SITE_REMOVAL](state);

      expect(state.isLoading).toBe(true);
    });
  });

  describe('RECEIVE_SITE_REMOVAL_SUCCESS', () => {
    beforeEach(() => {
      state.isLoading = true;
      state.sites = [{ id: 1 }, { id: 2 }];
      state.siteToBeRemoved = 1;
    });

    it('removes site, clears siteToBeRemoved, and ends loading', () => {
      mutations[types.RECEIVE_SITE_REMOVAL_SUCCESS](state);

      expect(state.isLoading).toBe(false);
      expect(state.sites).toEqual([{ id: 2 }]);
      expect(state.siteToBeRemoved).toEqual(null);
    });
  });

  describe('RECEIVE_SITE_REMOVAL_ERROR', () => {
    beforeEach(() => {
      state.isLoading = true;
      state.siteToBeRemoved = 1;
    });

    it('resets state', () => {
      mutations[types.RECEIVE_SITE_REMOVAL_ERROR](state);

      expect(state.isLoading).toBe(false);
      expect(state.siteToBeRemoved).toEqual(null);
    });
  });

  describe('SET_STATUS_FILTER', () => {
    it('sets statusFilter', () => {
      mutations[types.SET_STATUS_FILTER](state, 'healthy');

      expect(state.statusFilter).toBe('healthy');
    });
  });

  describe('SET_SEARCH_FILTER', () => {
    it('sets searchFilter', () => {
      mutations[types.SET_SEARCH_FILTER](state, 'search');

      expect(state.searchFilter).toBe('search');
    });
  });
});
