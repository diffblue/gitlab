import * as types from 'ee/audit_events/store/mutation_types';
import mutations from 'ee/audit_events/store/mutations';

describe('Audit Event mutations', () => {
  let state = null;
  const startDate = new Date('March 13, 2020 12:00:00');
  const endDate = new Date('April 13, 2020 12:00:00');

  beforeEach(() => {
    state = {};
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                  | payload                                                  | expectedState
    ${types.SET_FILTER_VALUE} | ${[{ type: 'User', value: { data: 1, operator: '=' } }]} | ${{ filterValue: [{ type: 'User', value: { data: 1, operator: '=' } }] }}
    ${types.SET_DATE_RANGE}   | ${{ startDate, endDate }}                                | ${{ startDate, endDate }}
    ${types.SET_SORT_BY}      | ${'created_asc'}                                         | ${{ sortBy: 'created_asc' }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      state = {};
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );

  describe(`${types.INITIALIZE_AUDIT_EVENTS}`, () => {
    const payload = {
      entity_id: '1',
      entity_type: 'User',
      created_after: startDate,
      created_before: endDate,
      sort: 'created_asc',
    };

    const createFilterValue = (data) => {
      return [{ type: payload.entity_type, value: { data, operator: '=' } }];
    };

    it.each`
      stateKey         | expectedState
      ${'filterValue'} | ${createFilterValue(payload.entity_id)}
      ${'startDate'}   | ${payload.created_after}
      ${'endDate'}     | ${payload.created_before}
      ${'sortBy'}      | ${payload.sort}
    `('state.$stateKey should be set to $expectedState', ({ stateKey, expectedState }) => {
      state = {};
      mutations[types.INITIALIZE_AUDIT_EVENTS](state, payload);

      expect(state[stateKey]).toEqual(expectedState);
    });

    it.each`
      payloadKey           | payloadValue
      ${'entity_id'}       | ${'1'}
      ${'entity_username'} | ${'abc'}
      ${'author_username'} | ${'abc'}
    `('sets the filter value when provided with a $payloadKey', ({ payloadKey, payloadValue }) => {
      const payloadWithValue = {
        ...payload,
        entity_id: undefined,
        [payloadKey]: payloadValue,
      };

      mutations[types.INITIALIZE_AUDIT_EVENTS](state, payloadWithValue);
      expect(state.filterValue).toEqual(createFilterValue(payloadValue));
    });
  });
});
