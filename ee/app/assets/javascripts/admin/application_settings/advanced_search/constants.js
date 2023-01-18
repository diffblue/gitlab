import { __, s__ } from '~/locale';

export const MINIMUM_QUERY_LENGTH = 3;
export const NO_RESULTS_TEXT = __('No results found.');
export const SEARCH_QUERY_TOO_SHORT = __('Enter at least three characters to search.');
export const ENTITIES_FETCH_ERROR = s__(
  'AdvancedSearch|Could not fetch index entities. Please try again later.',
);
