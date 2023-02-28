export default ({ namespaceId = null, namespaceName = null, userCapSet = false } = {}) => ({
  isLoading: false,
  hasError: false,
  alertMessage: '',
  alertVariant: '',
  namespaceId,
  namespaceName,
  members: [],
  total: null,
  page: null,
  perPage: null,
  approveAllMembersLoading: false,
  approveAllMembersDisabled: true,
  userCapSet,
});
