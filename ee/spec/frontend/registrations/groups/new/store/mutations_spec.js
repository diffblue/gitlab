import * as types from 'ee/registrations/groups/new/store/mutation_types';
import mutations from 'ee/registrations/groups/new/store/mutations';
import state from 'ee/registrations/groups/new/store/state';

describe('Mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_STORE_GROUP_NAME', () => {
    it('should set storeGroupName', () => {
      mutations[types.SET_STORE_GROUP_NAME](stateCopy, 'name');

      expect(stateCopy.storeGroupName).toEqual('name');
    });
  });

  describe('SET_STORE_GROUP_PATH', () => {
    it('should set storeGroupPath', () => {
      mutations[types.SET_STORE_GROUP_PATH](stateCopy, 'path');

      expect(stateCopy.storeGroupPath).toEqual('path');
    });
  });
});
