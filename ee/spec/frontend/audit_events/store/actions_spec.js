import * as actions from 'ee/audit_events/store/actions';
import * as types from 'ee/audit_events/store/mutation_types';
import createState from 'ee/audit_events/store/state';
import setWindowLocation from 'helpers/set_window_location_helper';
import testAction from 'helpers/vuex_action_helper';
import * as urlUtility from '~/lib/utils/url_utility';

describe('Audit Event actions', () => {
  let state;
  const startDate = new Date('March 13, 2020 12:00:00');
  const endDate = new Date('April 13, 2020 12:00:00');

  beforeEach(() => {
    state = createState();
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    action            | type                    | payload
    ${'setDateRange'} | ${types.SET_DATE_RANGE} | ${{ startDate, endDate }}
    ${'setSortBy'}    | ${types.SET_SORT_BY}    | ${'created_asc'}
  `(
    '$action should commit $type with $payload and dispatches "searchForAuditEvents"',
    ({ action, type, payload }) => {
      testAction(
        actions[action],
        payload,
        state,
        [
          {
            type,
            payload,
          },
        ],
        [{ type: 'searchForAuditEvents' }],
      );
    },
  );

  it('setFilterValue action should commit to the store', () => {
    const payload = [{ type: 'User', value: { data: '@root', operator: '=' } }];
    testAction(actions.setFilterValue, payload, state, [{ type: types.SET_FILTER_VALUE, payload }]);
  });

  describe('searchForAuditEvents', () => {
    let spy;

    beforeEach(() => {
      setWindowLocation('https://test/');
      spy = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});
    });

    afterEach(() => {
      spy.mockRestore();
    });

    describe('with a default state', () => {
      it('should call visitUrl without a search query', () => {
        return testAction(actions.searchForAuditEvents, null, state, []).then(() => {
          expect(spy).toHaveBeenCalledWith('https://test/');
        });
      });
    });

    describe('with a state that has a search query', () => {
      beforeEach(() => {
        state.sortBy = 'created_asc';
      });

      it('should call visitUrl with a search query', () => {
        return testAction(actions.searchForAuditEvents, null, state, []).then(() => {
          expect(spy).toHaveBeenCalledWith('https://test/?sort=created_asc');
        });
      });
    });
  });

  describe('initializeAuditEvents', () => {
    describe('with an empty search query', () => {
      beforeEach(() => {
        setWindowLocation('?');
      });

      it(`commits "${types.INITIALIZE_AUDIT_EVENTS}" with empty dates`, () => {
        testAction(actions.initializeAuditEvents, null, state, [
          {
            type: types.INITIALIZE_AUDIT_EVENTS,
            payload: {
              created_after: null,
              created_before: null,
              author_username: null,
              entity_username: null,
              entity_type: undefined,
            },
          },
        ]);
      });
    });

    describe('with a full search query', () => {
      beforeEach(() => {
        setWindowLocation(
          '?sort=created_desc&entity_type=Project&entity_id=44&created_after=2020-06-05&created_before=2020-06-25',
        );
      });

      it(`commits "${types.INITIALIZE_AUDIT_EVENTS}" with the query data`, () => {
        testAction(actions.initializeAuditEvents, null, state, [
          {
            type: types.INITIALIZE_AUDIT_EVENTS,
            payload: {
              created_after: new Date('2020-06-05T00:00:00.000Z'),
              created_before: new Date('2020-06-25T00:00:00.000Z'),
              entity_id: '44',
              entity_type: 'project',
              sort: 'created_desc',
              author_username: null,
              entity_username: null,
            },
          },
        ]);
      });
    });
  });
});
