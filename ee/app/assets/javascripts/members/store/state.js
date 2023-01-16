import createState from '~/members/store/state';

export default (initialState) => {
  const { disableTwoFactorPath, ldapOverridePath } = initialState;

  return {
    disableTwoFactorPath,
    disableTwoFactorModalData: {},
    disableTwoFactorModalVisible: false,
    memberToOverride: null,
    ldapOverridePath,
    ldapOverrideConfirmationModalVisible: false,
    ...createState(initialState),
  };
};
