import testAction from 'helpers/vuex_action_helper';
import * as types from 'ee/registrations/groups/new/store/mutation_types';
import state from 'ee/registrations/groups/new/store/state';
import { setStoreGroupName, setStoreGroupPath } from 'ee/registrations/groups/new/store/actions';

describe('Actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('setStoreGroupName', () => {
    it('should commit SET_STORE_GROUP_NAME mutation', () => {
      return testAction(
        setStoreGroupName,
        'name',
        mockedState,
        [{ type: types.SET_STORE_GROUP_NAME, payload: 'name' }],
        [],
      );
    });
  });

  describe('setStoreGroupPath', () => {
    it('should commit SET_STORE_GROUP_PATH mutation', () => {
      return testAction(
        setStoreGroupPath,
        'path',
        mockedState,
        [{ type: types.SET_STORE_GROUP_PATH, payload: 'path' }],
        [],
      );
    });
  });
});
