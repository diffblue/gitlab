import * as getters from 'ee/usage_quotas/seats/store/getters';
import State from 'ee/usage_quotas/seats/store/state';
import { mockDataSeats, mockTableItems } from 'ee_jest/usage_quotas/seats/mock_data';

describe('Usage Quotas Seats getters', () => {
  let state;

  beforeEach(() => {
    state = State();
  });

  describe('Table items', () => {
    it('should return expected value if data is provided', () => {
      state.members = [...mockDataSeats.data];

      expect(getters.tableItems(state)).toEqual(mockTableItems);
    });

    it('should return an empty array if data is not provided', () => {
      state.members = [];

      expect(getters.tableItems(state)).toEqual([]);
    });
  });

  describe('isLoading', () => {
    beforeEach(() => {
      state.isLoadingBillableMembers = false;
      state.isLoadingGitlabSubscription = false;
      state.isChangingMembershipState = false;
      state.isRemovingBillableMember = false;
    });

    it('returns false if nothing is being loaded', () => {
      expect(getters.isLoading(state)).toEqual(false);
    });

    it.each([
      'isLoadingBillableMembers',
      'isLoadingGitlabSubscription',
      'isChangingMembershipState',
      'isRemovingBillableMember',
    ])('returns true if %s is being loaded', (key) => {
      state[key] = true;

      expect(getters.isLoading(state)).toEqual(true);
    });
  });
});
