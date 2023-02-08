export default ({ namespaceId = null, namespaceName = null } = {}) => ({
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
});
