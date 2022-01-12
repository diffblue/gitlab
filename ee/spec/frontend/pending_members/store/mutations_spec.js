import { mockDataMembers } from 'ee_jest/pending_members/mock_data';
import * as types from 'ee/pending_members/store/mutation_types';
import mutations from 'ee/pending_members/store/mutations';
import createState from 'ee/pending_members/store/state';

describe('Pending members mutations', () => {
  const alertMessage = 'This is an alert';
  const alertVariant = 'info';
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

  describe(types.DISMISS_ALERT, () => {
    beforeEach(() => {
      state.alertMessage = alertMessage;
    });

    it('cleans alertMessage state', () => {
      mutations[types.DISMISS_ALERT](state);

      expect(state.alertMessage).toBe('');
    });
  });

  describe(types.SHOW_ALERT, () => {
    beforeEach(() => {
      state.alertMessage = '';
      state.alertVariant = '';
    });

    it('sets alertMessage and alertVariant', () => {
      mutations[types.SHOW_ALERT](state, { alertMessage, alertVariant });

      expect(state.alertMessage).toBe(alertMessage);
      expect(state.alertVariant).toBe(alertVariant);
    });
  });

  describe('member specific mutations', () => {
    const memberId = mockDataMembers.data[0].id;

    beforeEach(() => {
      state.members = mockDataMembers.data;
    });

    describe(types.SET_MEMBER_AS_LOADING, () => {
      it('sets member loading state to true', () => {
        mutations[types.SET_MEMBER_AS_LOADING](state, memberId);
        const member = state.members.find((m) => m.id === memberId);
        expect(member.loading).toBeTruthy();
      });
    });

    describe(types.SET_MEMBER_AS_APPROVED, () => {
      it('sets member loading state to false and approved state to true', () => {
        mutations[types.SET_MEMBER_AS_APPROVED](state, memberId);
        const member = state.members.find((m) => m.id === memberId);
        expect(member.loading).toBeFalsy();
        expect(member.approved).toBeTruthy();
      });
    });

    describe(types.SHOW_ALERT, () => {
      beforeEach(() => {
        state.alertMessage = '';
        state.alertVariant = '';
      });

      it('sets alertMessage and alertVariant', () => {
        mutations[types.SHOW_ALERT](state, {
          memberId,
          alertMessage: `${alertMessage}%{user}`,
          alertVariant,
        });
        const member = state.members.find((m) => m.id === memberId);

        expect(state.alertMessage).toBe(`${alertMessage}${member.name}`);
        expect(state.alertVariant).toBe(alertVariant);
      });
    });
  });
});
