import * as types from 'ee/members/store/mutation_types';
import mutations from 'ee/members/store/mutations';
import { members, member } from 'jest/members/mock_data';

describe('Vuex members mutations', () => {
  describe(types.SHOW_DISABLE_TWO_FACTOR_MODAL, () => {
    it('sets `disableTwoFactorModalData` and `disableTwoFactorModalVisible`', () => {
      const state = {
        disableTwoFactorModalData: {},
        disableTwoFactorModalVisible: false,
      };

      const modalData = { userID: 5, name: 'John Malone' };
      mutations[types.SHOW_DISABLE_TWO_FACTOR_MODAL](state, modalData);

      expect(state).toEqual({
        disableTwoFactorModalData: modalData,
        disableTwoFactorModalVisible: true,
      });
    });
  });

  describe(types.HIDE_DISABLE_TWO_FACTOR_MODAL, () => {
    it('sets `disableTwoFactorModalData` and `disableTwoFactorModalVisible`', () => {
      const state = {
        disableTwoFactorModalData: { userID: 5, name: 'John Malone' },
        disableTwoFactorModalVisible: true,
      };

      mutations[types.HIDE_DISABLE_TWO_FACTOR_MODAL](state);

      expect(state).toEqual({
        disableTwoFactorModalData: null,
        disableTwoFactorModalVisible: false,
      });
    });
  });

  describe(types.RECEIVE_LDAP_OVERRIDE_SUCCESS, () => {
    it('updates member', () => {
      const state = {
        members,
      };

      mutations[types.RECEIVE_LDAP_OVERRIDE_SUCCESS](state, {
        memberId: members[0].id,
        override: true,
      });

      expect(state.members[0].isOverridden).toEqual(true);
    });
  });

  describe(types.RECEIVE_LDAP_OVERRIDE_ERROR, () => {
    const state = {
      showError: false,
      errorMessage: '',
    };

    describe('when enabling LDAP override', () => {
      it('shows error message', () => {
        mutations[types.RECEIVE_LDAP_OVERRIDE_ERROR](state, true);

        expect(state.showError).toBe(true);
        expect(state.errorMessage).toBe(
          'An error occurred while trying to enable LDAP override, please try again.',
        );
      });
    });

    describe('when disabling LDAP override', () => {
      it('shows error message', () => {
        mutations[types.RECEIVE_LDAP_OVERRIDE_ERROR](state, false);

        expect(state.showError).toBe(true);
        expect(state.errorMessage).toBe(
          'An error occurred while trying to revert to LDAP group sync settings, please try again.',
        );
      });
    });
  });

  describe(types.SHOW_LDAP_OVERRIDE_CONFIRMATION_MODAL, () => {
    it('sets `ldapOverrideConfirmationModalVisible` and `memberToOverride`', () => {
      const state = {
        memberToOverride: null,
        ldapOverrideConfirmationModalVisible: false,
      };

      mutations[types.SHOW_LDAP_OVERRIDE_CONFIRMATION_MODAL](state, member);

      expect(state).toEqual({
        memberToOverride: member,
        ldapOverrideConfirmationModalVisible: true,
      });
    });
  });

  describe(types.HIDE_LDAP_OVERRIDE_CONFIRMATION_MODAL, () => {
    it('sets `ldapOverrideConfirmationModalVisible` to `false`', () => {
      const state = {
        ldapOverrideConfirmationModalVisible: true,
      };

      mutations[types.HIDE_LDAP_OVERRIDE_CONFIRMATION_MODAL](state);

      expect(state.ldapOverrideConfirmationModalVisible).toBe(false);
    });
  });
});
