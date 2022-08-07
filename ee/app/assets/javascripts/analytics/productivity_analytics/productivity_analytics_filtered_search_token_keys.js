import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import { __ } from '~/locale';

const tokenKeys = [
  {
    formattedKey: __('Author'),
    key: 'author',
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'pencil',
    tag: '@author',
  },
  {
    formattedKey: __('Milestone'),
    key: 'milestone',
    type: 'string',
    param: 'title',
    symbol: '%',
    icon: 'clock',
    tag: '%milestone',
  },
  {
    formattedKey: __('Label'),
    key: 'label',
    type: 'array',
    param: 'name[]',
    symbol: '~',
    icon: 'labels',
    tag: '~label',
  },
];

const alternativeTokenKeys = [
  {
    formattedKey: __('Label'),
    key: 'label',
    type: 'string',
    param: 'name',
    symbol: '~',
  },
];

const ProductivityAnalyticsFilteredSearchTokenKeys = new FilteredSearchTokenKeys(
  tokenKeys,
  alternativeTokenKeys,
);

export default ProductivityAnalyticsFilteredSearchTokenKeys;
