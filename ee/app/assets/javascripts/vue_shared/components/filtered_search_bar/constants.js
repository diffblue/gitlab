import { __ } from '~/locale';
import {
  DEFAULT_NONE_ANY,
  FILTER_CURRENT,
} from '~/vue_shared/components/filtered_search_bar/constants';

export * from '~/vue_shared/components/filtered_search_bar/constants';

export const WEIGHT_TOKEN_SUGGESTIONS_SIZE = 21;

export const DEFAULT_ITERATIONS = DEFAULT_NONE_ANY.concat([
  { value: FILTER_CURRENT, text: __('Current') },
]);

export const TOKEN_TITLE_ITERATION = __('Iteration');
export const TOKEN_TITLE_EPIC = __('Epic');
export const TOKEN_TITLE_WEIGHT = __('Weight');
