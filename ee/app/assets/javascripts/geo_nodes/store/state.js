const createState = ({ replicableTypes, searchFilter }) => ({
  replicableTypes,
  searchFilter,
  statusFilter: null,
  nodes: [],
  isLoading: false,
  nodeToBeRemoved: null,
});
export default createState;
