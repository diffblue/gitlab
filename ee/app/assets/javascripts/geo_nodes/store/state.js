const createState = ({ primaryVersion, primaryRevision, replicableTypes }) => ({
  primaryVersion,
  primaryRevision,
  replicableTypes,
  nodes: [],
  isLoading: false,
  nodeToBeRemoved: null,
  statusFilter: null,
});
export default createState;
