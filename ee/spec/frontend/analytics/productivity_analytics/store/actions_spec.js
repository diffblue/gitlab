import * as actions from 'ee/analytics/productivity_analytics/store/actions';
import SET_ENDPOINT from 'ee/analytics/productivity_analytics/store/mutation_types';
import getInitialState from 'ee/analytics/productivity_analytics/store/state';
import testAction from 'helpers/vuex_action_helper';

describe('Productivity analytics actions', () => {
  describe('setEndpoint', () => {
    it('commits the SET_ENDPOINT mutation', () =>
      testAction(
        actions.setEndpoint,
        'endpoint.json',
        getInitialState(),
        [
          {
            type: SET_ENDPOINT,
            payload: 'endpoint.json',
          },
        ],
        [],
      ));
  });
});
