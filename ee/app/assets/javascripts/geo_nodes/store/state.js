const createState = ({ replicableTypes, searchFilter }) => ({
  replicableTypes,
  searchFilter,
  statusFilter: null,
  sites: [],
  isLoading: false,
  siteToBeRemoved: null,
});
export default createState;
