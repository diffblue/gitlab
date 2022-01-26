import * as getters from 'ee/usage_quotas/seats/store/getters';
import State from 'ee/usage_quotas/seats/store/state';
import {
  mockDataSeats,
  mockTableItems,
  mockMemberDetails,
} from 'ee_jest/usage_quotas/seats/mock_data';

describe('Seat usage table getters', () => {
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

  describe('membershipsById', () => {
    describe('when data is not availlable', () => {
      it('returns a base state', () => {
        expect(getters.membershipsById(state)(0)).toEqual({
          isLoading: true,
          items: [],
        });
      });
    });

    describe('when data is available', () => {
      it('returns user details state', () => {
        state.userDetails[0] = {
          isLoading: false,
          items: mockMemberDetails,
        };

        expect(getters.membershipsById(state)(0)).toEqual({
          isLoading: false,
          items: mockMemberDetails,
        });
      });
    });
  });
});
