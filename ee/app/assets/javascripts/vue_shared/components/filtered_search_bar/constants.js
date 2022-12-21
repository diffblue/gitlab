import { __ } from '~/locale';
import {
  OPTION_ANY,
  OPTION_CURRENT,
  OPTIONS_NONE_ANY,
} from '~/vue_shared/components/filtered_search_bar/constants';

export * from '~/vue_shared/components/filtered_search_bar/constants';

export const WEIGHT_TOKEN_SUGGESTIONS_SIZE = 21;

export const DEFAULT_ITERATIONS = OPTIONS_NONE_ANY.concat(OPTION_CURRENT);
export const DEFAULT_CADENCES = [OPTION_ANY, OPTION_CURRENT];
export const DEFAULT_HEALTH_STATUSES = OPTIONS_NONE_ANY;

export const HEALTH_SUGGESTIONS = [
  { title: __('On track'), value: 'onTrack' },
  { title: __('Needs attention'), value: 'needsAttention' },
  { title: __('At risk'), value: 'atRisk' },
];

export const TOKEN_TITLE_ITERATION = __('Iteration');
export const TOKEN_TITLE_EPIC = __('Epic');
export const TOKEN_TITLE_WEIGHT = __('Weight');
export const TOKEN_TITLE_HEALTH = __('Health');
