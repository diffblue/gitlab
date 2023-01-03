import * as actions from 'ee/dependencies/store/actions';
import { DEPENDENCY_LIST_TYPES } from 'ee/dependencies/store/constants';
import * as types from 'ee/dependencies/store/mutation_types';
import createState from 'ee/dependencies/store/state';
import { TEST_HOST } from 'helpers/test_constants';
import testAction from 'helpers/vuex_action_helper';

describe('Dependencies actions', () => {
  describe('addListType', () => {
    it('commits the ADD_LIST_TYPE mutation', () => {
      const payload = DEPENDENCY_LIST_TYPES.vulnerable;

      return testAction(
        actions.addListType,
        payload,
        createState(),
        [
          {
            type: types.ADD_LIST_TYPE,
            payload,
          },
        ],
        [],
      );
    });
  });

  describe.each`
    actionName                         | payload
    ${'setDependenciesEndpoint'}       | ${TEST_HOST}
    ${'setExportDependenciesEndpoint'} | ${TEST_HOST}
    ${'fetchDependencies'}             | ${undefined}
  `('$actionName', ({ actionName, payload }) => {
    it(`dispatches the ${actionName} action on each list module`, () => {
      const state = createState();
      state.listTypes.push({ namespace: 'foo' });

      return testAction(
        actions[actionName],
        payload,
        state,
        [],
        [
          {
            type: `allDependencies/${actionName}`,
            payload,
          },
          {
            type: `foo/${actionName}`,
            payload,
          },
        ],
      );
    });
  });

  describe('setCurrentList', () => {
    let payload;
    let state;

    beforeEach(() => {
      state = {
        listTypes: [{ namespace: 'foo' }, { namespace: 'bar' }],
      };
    });

    describe('given an existing namespace', () => {
      beforeEach(() => {
        payload = 'bar';
      });

      it('commits the SET_CURRENT_LIST mutation if given a valid list', () =>
        testAction(
          actions.setCurrentList,
          payload,
          state,
          [
            {
              type: types.SET_CURRENT_LIST,
              payload: 'bar',
            },
          ],
          [],
        ));
    });

    describe('given a non-existent namespace', () => {
      beforeEach(() => {
        payload = 'qux';
      });

      it('does nothing', () => testAction(actions.setCurrentList, payload, state, [], []));
    });
  });
});
