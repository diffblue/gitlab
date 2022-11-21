import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import {
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
} from '~/vue_shared/components/filtered_search_bar/constants';

const tokenKeys = [
  {
    formattedKey: TOKEN_TITLE_AUTHOR,
    key: TOKEN_TYPE_AUTHOR,
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'pencil',
    tag: '@author',
  },
  {
    formattedKey: TOKEN_TITLE_MILESTONE,
    key: TOKEN_TYPE_MILESTONE,
    type: 'string',
    param: 'title',
    symbol: '%',
    icon: 'clock',
    tag: '%milestone',
  },
  {
    formattedKey: TOKEN_TITLE_LABEL,
    key: TOKEN_TYPE_LABEL,
    type: 'array',
    param: 'name[]',
    symbol: '~',
    icon: 'labels',
    tag: '~label',
  },
];

const alternativeTokenKeys = [
  {
    formattedKey: TOKEN_TITLE_LABEL,
    key: TOKEN_TYPE_LABEL,
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
