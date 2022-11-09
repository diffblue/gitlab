import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import { __ } from '~/locale';
import {
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MY_REACTION,
} from '~/vue_shared/components/filtered_search_bar/constants';

const tokenKeys = [
  {
    formattedKey: TOKEN_TITLE_AUTHOR,
    key: 'author',
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'pencil',
    tag: '@author',
  },
  {
    formattedKey: TOKEN_TITLE_LABEL,
    key: 'label',
    type: 'array',
    param: 'name[]',
    symbol: '~',
    icon: 'labels',
    tag: '~label',
  },
];

if (gon.current_user_id) {
  // Appending tokenkeys only logged-in
  tokenKeys.push({
    formattedKey: TOKEN_TITLE_MY_REACTION,
    key: 'my-reaction',
    type: 'string',
    param: 'emoji',
    symbol: '',
    icon: 'thumb-up',
    tag: 'emoji',
  });
}

const alternativeTokenKeys = [
  {
    formattedKey: TOKEN_TITLE_LABEL,
    key: 'label',
    type: 'string',
    param: 'name',
    symbol: '~',
  },
];

const conditions = [
  {
    url: 'label_name[]=No+Label',
    tokenKey: 'label',
    value: 'none',
    operator: '=',
  },
  {
    url: 'not[label_name][]=No+Label',
    tokenKey: 'label',
    value: 'none',
    operator: '!=',
  },
  {
    url: 'my_reaction_emoji=None',
    tokenKey: 'my-reaction',
    value: __('None'),
  },
  {
    url: 'my_reaction_emoji=Any',
    tokenKey: 'my-reaction',
    value: __('Any'),
  },
];

const EpicsFilteredSearchTokenKeysEE = new FilteredSearchTokenKeys(
  [...tokenKeys],
  alternativeTokenKeys,
  [...conditions],
);

export default EpicsFilteredSearchTokenKeysEE;
