import { parseBoolean } from '~/lib/utils/common_utils';
import { FILTER_STATES, DEFAULT_PAGE_SIZE } from '../constants';

const createState = ({
  replicableType,
  graphqlFieldName,
  verificationEnabled,
  geoCurrentSiteId,
  geoTargetSiteId,
}) => ({
  replicableType,
  graphqlFieldName,
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
  currentFilterIndex: 0,
  filterOptions: Object.values(FILTER_STATES),
});
export default createState;
