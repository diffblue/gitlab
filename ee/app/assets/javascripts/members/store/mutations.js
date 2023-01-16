import Vue from 'vue';
import { s__ } from '~/locale';
import CEMutations from '~/members/store/mutations';
import { findMember } from '~/members/store/utils';
import * as types from './mutation_types';

export default {
  ...CEMutations,
  [types.SHOW_DISABLE_TWO_FACTOR_MODAL](state, modalData) {
    state.disableTwoFactorModalData = modalData;
    state.disableTwoFactorModalVisible = true;
  },
  [types.HIDE_DISABLE_TWO_FACTOR_MODAL](state) {
    state.disableTwoFactorModalData = null;
    state.disableTwoFactorModalVisible = false;
  },
  [types.RECEIVE_LDAP_OVERRIDE_SUCCESS](state, { memberId, override }) {
    const member = findMember(state, memberId);

    if (!member) {
      return;
    }

    Vue.set(member, 'isOverridden', override);
  },
  [types.RECEIVE_LDAP_OVERRIDE_ERROR](state, override) {
    state.errorMessage = override
      ? s__('Members|An error occurred while trying to enable LDAP override, please try again.')
      : s__(
          'Members|An error occurred while trying to revert to LDAP group sync settings, please try again.',
        );
    state.showError = true;
  },
  [types.SHOW_LDAP_OVERRIDE_CONFIRMATION_MODAL](state, member) {
    state.ldapOverrideConfirmationModalVisible = true;
    state.memberToOverride = member;
  },
  [types.HIDE_LDAP_OVERRIDE_CONFIRMATION_MODAL](state) {
    state.ldapOverrideConfirmationModalVisible = false;
  },
};
