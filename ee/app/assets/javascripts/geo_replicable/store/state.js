import { parseBoolean } from '~/lib/utils/common_utils';

const createState = ({
  replicableType,
  graphqlFieldName,
  graphqlMutationRegistryClass,
  verificationEnabled,
  geoCurrentSiteId,
  geoTargetSiteId,
}) => ({
  replicableType,
  graphqlFieldName,
  graphqlMutationRegistryClass,
  verificationEnabled: parseBoolean(verificationEnabled),
  geoCurrentSiteId,
  geoTargetSiteId,
  isLoading: false,

  replicableItems: [],
  paginationData: {
    hasNextPage: false,
    hasPreviousPage: false,
    startCursor: '',
    endCursor: '',
  },

  searchFilter: '',
  statusFilter: '',
});
export default createState;
