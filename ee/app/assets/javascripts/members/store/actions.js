import axios from '~/lib/utils/axios_utils';
import * as types from './mutation_types';

export * from '~/members/store/actions';

export const showDisableTwoFactorModal = ({ commit }, modalData) => {
  commit(types.SHOW_DISABLE_TWO_FACTOR_MODAL, modalData);
};

export const hideDisableTwoFactorModal = ({ commit }) => {
  commit(types.HIDE_DISABLE_TWO_FACTOR_MODAL);
};

export const updateLdapOverride = async ({ state, commit }, { memberId, override }) => {
  try {
    await axios.patch(
      state.ldapOverridePath.replace(':id', memberId),
      state.requestFormatter({ override }),
    );

    commit(types.RECEIVE_LDAP_OVERRIDE_SUCCESS, {
      memberId,
      override,
    });
  } catch (error) {
    commit(types.RECEIVE_LDAP_OVERRIDE_ERROR, override);

    throw error;
  }
};

export const showLdapOverrideConfirmationModal = ({ commit }, member) => {
  commit(types.SHOW_LDAP_OVERRIDE_CONFIRMATION_MODAL, member);
};

export const hideLdapOverrideConfirmationModal = ({ commit }) => {
  commit(types.HIDE_LDAP_OVERRIDE_CONFIRMATION_MODAL);
};
