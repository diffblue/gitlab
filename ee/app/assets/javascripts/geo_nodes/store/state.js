const createState = ({ primaryVersion, primaryRevision, replicableTypes, searchFilter }) => ({
  primaryVersion,
  primaryRevision,
  replicableTypes,
  searchFilter,
  statusFilter: null,
  nodes: [],
  isLoading: false,
  nodeToBeRemoved: null,
});
export default createState;
