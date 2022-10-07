import * as types from 'ee/usage_quotas/seats/store/mutation_types';
import mutations from 'ee/usage_quotas/seats/store/mutations';
import createState from 'ee/usage_quotas/seats/store/state';
import {
  mockDataSeats,
  mockMemberDetails,
  mockUserSubscription,
} from 'ee_jest/usage_quotas/seats/mock_data';

describe('Usage Quotas Seats mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('GitLab subscription', () => {
    it(`${types.REQUEST_GITLAB_SUBSCRIPTION}`, () => {
      state.isLoadingGitlabSubscription = false;
      state.hasError = true;

      mutations[types.REQUEST_GITLAB_SUBSCRIPTION](state);

      expect(state.isLoadingGitlabSubscription).toBe(true);
      expect(state.hasError).toBe(false);
    });

    describe(types.RECEIVE_GITLAB_SUBSCRIPTION_SUCCESS, () => {
      describe('when subscription data is passed', () => {
        beforeEach(() => {
          state.isLoadingGitlabSubscription = true;

          mutations[types.RECEIVE_GITLAB_SUBSCRIPTION_SUCCESS](state, mockUserSubscription);
        });

        it('sets state as expected', () => {
          expect(state).toMatchObject({
            seatsInSubscription: mockUserSubscription.usage.seats_in_subscription,
            seatsInUse: mockUserSubscription.usage.seats_in_use,
            maxSeatsUsed: mockUserSubscription.usage.max_seats_used,
            seatsOwed: mockUserSubscription.usage.seats_owed,
            hasReachedFreePlanLimit: false,
            isLoadingGitlabSubscription: false,
            activeTrial: mockUserSubscription.plan.trial,
          });
        });

        describe('when hasLimitedFreePlan: true', () => {
          it('sets hasReachedFreePlanLimit to false when limit has not been reached', () => {
            state = { ...state, hasLimitedFreePlan: true, maxFreeNamespaceSeats: 5 };

            mutations[types.RECEIVE_GITLAB_SUBSCRIPTION_SUCCESS](state, {
              ...mockUserSubscription,
              usage: { seats_in_use: 4 },
            });

            expect(state.hasReachedFreePlanLimit).toBe(false);
          });

          it('sets hasReachedFreePlanLimit to true when limit has been reached', () => {
            state = { ...state, hasLimitedFreePlan: true, maxFreeNamespaceSeats: 5 };

            mutations[types.RECEIVE_GITLAB_SUBSCRIPTION_SUCCESS](state, {
              ...mockUserSubscription,
              usage: { seats_in_use: 5 },
            });

            expect(state.hasReachedFreePlanLimit).toBe(true);
          });
        });

        describe('when plan is on trial', () => {
          it('sets activeTrial to true', () => {
            mutations[types.RECEIVE_GITLAB_SUBSCRIPTION_SUCCESS](state, {
              ...mockUserSubscription,
              plan: { trial: true },
            });

            expect(state.activeTrial).toBe(true);
          });
        });
      });

      it('defaults values when subscription data is not passed', () => {
        state.isLoadingGitlabSubscription = true;

        mutations[types.RECEIVE_GITLAB_SUBSCRIPTION_SUCCESS](state, {});

        expect(state).toMatchObject({
          seatsInSubscription: 0,
          seatsInUse: 0,
          maxSeatsUsed: 0,
          seatsOwed: 0,
          isLoadingGitlabSubscription: false,
          activeTrial: false,
        });
      });
    });

    it(`${types.RECEIVE_GITLAB_SUBSCRIPTION_ERROR}`, () => {
      state.isLoadingGitlabSubscription = true;
      state.hasError = false;

      mutations[types.RECEIVE_GITLAB_SUBSCRIPTION_ERROR](state);

      expect(state.isLoadingGitlabSubscription).toBe(false);
      expect(state.hasError).toBe(true);
    });
  });

  describe('Search and sort', () => {
    describe(types.SET_SEARCH_QUERY, () => {
      it('sets the search state', () => {
        state.search = '';
        const SEARCH_STRING = 'a search string';
        mutations[types.SET_SEARCH_QUERY](state, SEARCH_STRING);

        expect(state.search).toBe(SEARCH_STRING);
      });

      it('sets the search state item to null', () => {
        state.search = 'a search string';
        mutations[types.SET_SEARCH_QUERY](state);
        expect(state.search).toBe(null);
      });
    });

    it(`${types.SET_CURRENT_PAGE}`, () => {
      state.page = 1;
      mutations[types.SET_CURRENT_PAGE](state, 42);
      expect(state.page).toBe(42);
    });

    it(`${types.SET_SORT_OPTION}`, () => {
      mutations[types.SET_SORT_OPTION](state, 'last_activity_on_desc');
      expect(state.sort).toBe('last_activity_on_desc');
    });
  });

  describe('Billable member list', () => {
    it(`${types.REQUEST_BILLABLE_MEMBERS}`, () => {
      state.isLoadingBillableMembers = false;
      state.hasError = true;
      mutations[types.REQUEST_BILLABLE_MEMBERS](state);
      expect(state).toMatchObject({
        isLoadingBillableMembers: true,
        hasError: false,
      });
    });

    it(`${types.RECEIVE_BILLABLE_MEMBERS_SUCCESS}`, () => {
      state.isLoadingBillableMembers = true;
      mutations[types.RECEIVE_BILLABLE_MEMBERS_SUCCESS](state, mockDataSeats);
      expect(state.members).toMatchObject(mockDataSeats.data);
      expect(state).toMatchObject({
        total: 3,
        page: 1,
        perPage: 1,
        isLoadingBillableMembers: false,
      });
    });

    it(`${types.RECEIVE_BILLABLE_MEMBERS_ERROR}`, () => {
      state.hasError = false;
      state.isLoadingBillableMembers = true;
      mutations[types.RECEIVE_BILLABLE_MEMBERS_ERROR](state);
      expect(state).toMatchObject({
        isLoadingBillableMembers: false,
        hasError: true,
      });
    });
  });

  describe('Billable member removal', () => {
    const memberToRemove = mockDataSeats.data[0];

    beforeEach(() => {
      state.billableMemberToRemove = { id: 42 };
      mutations[types.RECEIVE_BILLABLE_MEMBERS_SUCCESS](state, mockDataSeats);
    });

    it(`${types.SET_BILLABLE_MEMBER_TO_REMOVE}`, () => {
      mutations[types.SET_BILLABLE_MEMBER_TO_REMOVE](state, memberToRemove);

      expect(state.billableMemberToRemove).toMatchObject(memberToRemove);
    });

    it(`${types.REMOVE_BILLABLE_MEMBER}`, () => {
      mutations[types.REMOVE_BILLABLE_MEMBER](state, memberToRemove);

      expect(state).toMatchObject({ isRemovingBillableMember: true, hasError: false });
    });

    it(`${types.REMOVE_BILLABLE_MEMBER_SUCCESS}`, () => {
      mutations[types.REMOVE_BILLABLE_MEMBER_SUCCESS](state, memberToRemove);

      expect(state).toMatchObject({
        isRemovingBillableMember: false,
        billableMemberToRemove: null,
      });
    });

    it(`${types.REMOVE_BILLABLE_MEMBER_ERROR}`, () => {
      mutations[types.REMOVE_BILLABLE_MEMBER_ERROR](state, memberToRemove);

      expect(state).toMatchObject({
        isRemovingBillableMember: false,
        billableMemberToRemove: null,
      });
    });
  });

  describe('fetching billable member details', () => {
    const member = mockDataSeats.data[0];

    beforeEach(() => {
      delete state.userDetails[member.id];
    });

    it(`${types.FETCH_BILLABLE_MEMBER_DETAILS}`, () => {
      mutations[types.FETCH_BILLABLE_MEMBER_DETAILS](state, { memberId: member.id });

      expect(state.userDetails[member.id].isLoading).toBe(true);
    });

    it(`${types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS}`, () => {
      mutations[types.FETCH_BILLABLE_MEMBER_DETAILS_SUCCESS](state, {
        memberId: member.id,
        memberships: mockMemberDetails,
      });

      expect(state.userDetails[member.id].isLoading).toBe(false);
      expect(state.userDetails[member.id].items).toEqual(mockMemberDetails);
    });

    it(`${types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR}`, () => {
      mutations[types.FETCH_BILLABLE_MEMBER_DETAILS_ERROR](state, { memberId: member.id });

      expect(state.userDetails[member.id].isLoading).toBe(false);
    });
  });
});
