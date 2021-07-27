export default ({ namespaceId = null, namespaceName = null } = {}) => ({
  isLoading: false,
  hasError: false,
  namespaceId,
  namespaceName,
  members: [],
  total: null,
  page: null,
  perPage: null,
  billableMemberToRemove: null,
  userDetails: {},
  search: null,
  sort: 'last_activity_on_desc',
});
