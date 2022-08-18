import * as getters from 'ee/geo_replicable/store/getters';
import createState from 'ee/geo_replicable/store/state';
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
    currentFilterIndex | searchFilter | hasFilters
    ${0}               | ${''}        | ${false}
    ${0}               | ${'test'}    | ${true}
    ${1}               | ${''}        | ${true}
    ${1}               | ${'test'}    | ${true}
  `('hasFilters', ({ currentFilterIndex, searchFilter, hasFilters }) => {
    beforeEach(() => {
      state.currentFilterIndex = currentFilterIndex;
      state.searchFilter = searchFilter;
    });

    it(`when currentFilterIndex: ${currentFilterIndex} and searchFilter: "${searchFilter}" hasFilters returns ${hasFilters}`, () => {
      expect(getters.hasFilters(state)).toBe(hasFilters);
    });
  });
});
