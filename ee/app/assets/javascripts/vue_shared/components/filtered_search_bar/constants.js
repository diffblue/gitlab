import { __ } from '~/locale';
import {
  DEFAULT_LABEL_ANY,
  DEFAULT_NONE_ANY,
  FILTER_CURRENT,
} from '~/vue_shared/components/filtered_search_bar/constants';

export * from '~/vue_shared/components/filtered_search_bar/constants';

export const WEIGHT_TOKEN_SUGGESTIONS_SIZE = 21;

export const DEFAULT_CURRENT = { value: FILTER_CURRENT, text: __('Current') };

export const DEFAULT_ITERATIONS = DEFAULT_NONE_ANY.concat(DEFAULT_CURRENT);
export const DEFAULT_CADENCES = [DEFAULT_LABEL_ANY, DEFAULT_CURRENT];

export const HEALTH_SUGGESTIONS = [
  { title: __('On track'), value: 'onTrack' },
  { title: __('Needs attention'), value: 'needsAttention' },
  { title: __('At risk'), value: 'atRisk' },
];

export const HEALTH_DEFAULT_NONE_ANY = DEFAULT_NONE_ANY.map((opt) => ({
  ...opt,
  value: opt.value.toUpperCase(),
}));

export const TOKEN_TITLE_ITERATION = __('Iteration');
export const TOKEN_TITLE_EPIC = __('Epic');
export const TOKEN_TITLE_WEIGHT = __('Weight');
export const TOKEN_TITLE_HEALTH = __('Health');
