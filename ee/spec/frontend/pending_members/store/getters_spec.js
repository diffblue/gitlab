import * as getters from 'ee/pending_members/store/getters';
import State from 'ee/pending_members/store/state';
import { mockDataMembers } from 'ee_jest/pending_members/mock_data';

describe('Pending members getters', () => {
  let state;

  beforeEach(() => {
    state = State();
  });

  describe('Table items', () => {
    it('returns the expected value if data is provided', () => {
      state.members = [...mockDataMembers.data];

      expect(getters.tableItems(state)).toEqual(mockDataMembers.data);
    });

    it('returns an empty array if data is not provided', () => {
      state.members = [];

      expect(getters.tableItems(state)).toEqual([]);
    });
  });
});
