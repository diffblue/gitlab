import * as getters from 'ee/geo_replicable/store/getters';
import createState from 'ee/geo_replicable/store/state';
import { FILTER_OPTIONS } from 'ee/geo_replicable/constants';
import { MOCK_REPLICABLE_TYPE } from '../mock_data';

describe('GeoReplicable Store Getters', () => {
  let state;

  beforeEach(() => {
    state = createState({ replicableType: MOCK_REPLICABLE_TYPE, graphqlFieldName: null });
  });

  describe('replicableTypeName', () => {
    it('handles a single word replicable type', () => {
      state.replicableType = 'designs';

      expect(getters.replicableTypeName(state)).toBe('designs');
    });

    it('handles a multi-word replicable type', () => {
      state.replicableType = 'package_files';

      expect(getters.replicableTypeName(state)).toBe('package files');
    });
  });

  describe.each`
    statusFilter               | searchFilter | hasFilters
    ${FILTER_OPTIONS[0].value} | ${''}        | ${false}
    ${FILTER_OPTIONS[0].value} | ${'test'}    | ${true}
    ${FILTER_OPTIONS[1].value} | ${''}        | ${true}
    ${FILTER_OPTIONS[1].value} | ${'test'}    | ${true}
  `('hasFilters', ({ statusFilter, searchFilter, hasFilters }) => {
    beforeEach(() => {
      state.statusFilter = statusFilter;
      state.searchFilter = searchFilter;
    });

    it(`when statusFilter: ${statusFilter} and searchFilter: "${searchFilter}" hasFilters returns ${hasFilters}`, () => {
      expect(getters.hasFilters(state)).toBe(hasFilters);
    });
  });
});
