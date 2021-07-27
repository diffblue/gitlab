import * as types from 'ee/billings/seat_usage/store/mutation_types';
import mutations from 'ee/billings/seat_usage/store/mutations';
import createState from 'ee/billings/seat_usage/store/state';
import { mockDataSeats, mockMemberDetails } from 'ee_jest/billings/mock_data';

describe('EE billings seats module mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.REQUEST_BILLABLE_MEMBERS, () => {
    beforeEach(() => {
      mutations[types.REQUEST_BILLABLE_MEMBERS](state);
    });

    it('sets isLoading to true', () => {
      expect(state.isLoading).toBeTruthy();
    });

    it('sets hasError to false', () => {
      expect(state.hasError).toBeFalsy();
    });
  });

  describe(types.RECEIVE_BILLABLE_MEMBERS_SUCCESS, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_BILLABLE_MEMBERS_SUCCESS](state, mockDataSeats);
    });

    it('sets state as expected', () => {
      expect(state.members).toMatchObject(mockDataSeats.data);

      expect(state.total).toBe(3);
      expect(state.page).toBe(1);
      expect(state.perPage).toBe(1);
    });

    it('sets isLoading to false', () => {
      expect(state.isLoading).toBeFalsy();
    });
  });

  describe(types.RECEIVE_BILLABLE_MEMBERS_ERROR, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_BILLABLE_MEMBERS_ERROR](state);
    });

    it('sets isLoading to false', () => {
      expect(state.isLoading).toBeFalsy();
    });

    it('sets hasError to true', () => {
      expect(state.hasError).toBeTruthy();
    });
  });

  describe(types.SET_SEARCH_QUERY, () => {
    it('sets the search state', () => {
      const SEARCH_STRING = 'a search string';

      mutations[types.SET_SEARCH_QUERY](state, SEARCH_STRING);

      expect(state.search).toBe(SEARCH_STRING);
    });

    it('sets the search state item to null', () => {
      mutations[types.SET_SEARCH_QUERY](state);

      expect(state.search).toBe(null);
    });
  });

  describe(types.RESET_BILLABLE_MEMBERS, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_BILLABLE_MEMBERS_SUCCESS](state, mockDataSeats);
      mutations[types.RESET_BILLABLE_MEMBERS](state);
    });

    it('resets members state', () => {
      expect(state.members).toMatchObject([]);

      expect(state.total).toBeNull();
      expect(state.page).toBeNull();
      expect(state.perPage).toBeNull();

      expect(state.isLoading).toBeFalsy();
    });

    it('sets isLoading to false', () => {
      expect(state.isLoading).toBeFalsy();
    });
  });

  describe('member removal', () => {
    const memberToRemove = mockDataSeats.data[0];

    beforeEach(() => {
      mutations[types.RECEIVE_BILLABLE_MEMBERS_SUCCESS](state, mockDataSeats);
    });

    describe(types.SET_BILLABLE_MEMBER_TO_REMOVE, () => {
      it('sets the member to remove', () => {
        mutations[types.SET_BILLABLE_MEMBER_TO_REMOVE](state, memberToRemove);

        expect(state.billableMemberToRemove).toMatchObject(memberToRemove);
      });
    });

    describe(types.REMOVE_BILLABLE_MEMBER, () => {
      it('sets state to loading', () => {
        mutations[types.REMOVE_BILLABLE_MEMBER](state, memberToRemove);

        expect(state).toMatchObject({ isLoading: true, hasError: false });
      });
    });

    describe(types.REMOVE_BILLABLE_MEMBER_SUCCESS, () => {
      it('sets state to successfull', () => {
        mutations[types.REMOVE_BILLABLE_MEMBER_SUCCESS](state, memberToRemove);

        expect(state).toMatchObject({
          isLoading: false,
          hasError: false,
          billableMemberToRemove: null,
        });
      });
    });

    describe(types.REMOVE_BILLABLE_MEMBER_ERROR, () => {
      it('sets state to errored', () => {
        mutations[types.REMOVE_BILLABLE_MEMBER_ERROR](state, memberToRemove);

        expect(state).toMatchObject({
          isLoading: false,
          hasError: true,
          billableMemberToRemove: null,
        });
      });
    });
  });

  describe('fetching billable member details', () => {
    const member = mockDataSeats.data[0];

    describe(types.FETCH_BILLABLE_MEMBER_DETAILS, () => {
      it('sets the state to loading', () => {
        mutations[types.FETCH_BILLABLE_MEMBER_DETAILS](state, { memberId: member.id });

        expect(state.userDetails).toMatchObject({
          [member.id.toString()]: {
            isLoading: true,
          },
        });
      });
    });

    describe(types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS, () => {
      beforeEach(() => {
        mutations[types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS](state, {
          memberId: member.id,
          memberships: mockMemberDetails,
        });
      });

      it('sets the state to not loading', () => {
        expect(state.userDetails[member.id.toString()].isLoading).toBe(false);
      });

      it('sets the memberships to the state', () => {
        expect(state.userDetails[member.id.toString()].items).toEqual(mockMemberDetails);
      });
    });

    describe(types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR, () => {
      it('sets the state to not loading', () => {
        mutations[types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR](state, { memberId: member.id });

        expect(state.userDetails[member.id.toString()].isLoading).toBe(false);
      });
    });

    describe(types.SET_CURRENT_PAGE, () => {
      it('sets the page state', () => {
        mutations[types.SET_CURRENT_PAGE](state, 1);

        expect(state.page).toBe(1);
      });
    });

    describe(types.SET_SORT_OPTION, () => {
      it('sets the sort state', () => {
        mutations[types.SET_SORT_OPTION](state, 'last_activity_on_desc');

        expect(state.sort).toBe('last_activity_on_desc');
      });
    });
  });
});
