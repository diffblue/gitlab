import * as types from 'ee/analytics/cycle_analytics/store/modules/duration_chart/mutation_types';
import mutations from 'ee/analytics/cycle_analytics/store/modules/duration_chart/mutations';

import { transformedDurationData } from '../../../mock_data';

let state = null;

describe('DurationChart mutations', () => {
  beforeEach(() => {
    state = {};
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                             | stateKey       | value
    ${types.REQUEST_DURATION_DATA}       | ${'isLoading'} | ${true}
    ${types.RECEIVE_DURATION_DATA_ERROR} | ${'isLoading'} | ${false}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state);

    expect(state[stateKey]).toEqual(value);
  });

  it.each`
    mutation             | payload | expectedState
    ${types.SET_LOADING} | ${true} | ${{ isLoading: true }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      state = {
        selectedGroup: { fullPath: 'rad-stage' },
      };
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );

  describe(`${types.RECEIVE_DURATION_DATA_SUCCESS}`, () => {
    it('sets the data correctly and falsifies isLoading', () => {
      const stateWithData = {
        isLoading: true,
        durationData: [['something', 'random']],
      };

      mutations[types.RECEIVE_DURATION_DATA_SUCCESS](stateWithData, transformedDurationData);

      expect(stateWithData.isLoading).toBe(false);
      expect(stateWithData.durationData).toBe(transformedDurationData);
    });
  });
});
