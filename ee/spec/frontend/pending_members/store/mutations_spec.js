import { mockDataMembers } from 'ee_jest/pending_members/mock_data';
import * as types from 'ee/pending_members/store/mutation_types';
import mutations from 'ee/pending_members/store/mutations';
import createState from 'ee/pending_members/store/state';

describe('Pending members mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.REQUEST_PENDING_MEMBERS, () => {
    beforeEach(() => {
      mutations[types.REQUEST_PENDING_MEMBERS](state);
    });

    it('sets isLoading to true', () => {
      expect(state.isLoading).toBeTruthy();
    });

    it('sets hasError to false', () => {
      expect(state.hasError).toBeFalsy();
    });
  });

  describe(types.RECEIVE_PENDING_MEMBERS_SUCCESS, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_PENDING_MEMBERS_SUCCESS](state, mockDataMembers);
    });

    it('sets state as expected', () => {
      expect(state.members).toMatchObject(mockDataMembers.data);

      expect(state.total).toBe(3);
      expect(state.page).toBe(1);
      expect(state.perPage).toBe(1);
    });

    it('sets isLoading to false', () => {
      expect(state.isLoading).toBeFalsy();
    });
  });

  describe(types.RECEIVE_PENDING_MEMBERS_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_PENDING_MEMBERS_ERROR](state);
    });

    it('sets isLoading to false', () => {
      expect(state.isLoading).toBeFalsy();
    });

    it('sets hasError to true', () => {
      expect(state.hasError).toBeTruthy();
    });
  });

  describe(types.SET_CURRENT_PAGE, () => {
    it('sets the page state', () => {
      mutations[types.SET_CURRENT_PAGE](state, 1);

      expect(state.page).toBe(1);
    });
  });
});
