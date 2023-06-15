import { parseBoolean } from '~/lib/utils/common_utils';
import { DEFAULT_PAGE_SIZE } from '../constants';

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
  useGraphQl: Boolean(graphqlFieldName),
  isLoading: false,

  replicableItems: [],
  paginationData: {
    // GraphQL
    hasNextPage: false,
    hasPreviousPage: false,
    startCursor: '',
    endCursor: '',
    // RESTful
    total: 0,
    perPage: DEFAULT_PAGE_SIZE,
    page: 1,
  },

  searchFilter: '',
  statusFilter: '',
});
export default createState;
