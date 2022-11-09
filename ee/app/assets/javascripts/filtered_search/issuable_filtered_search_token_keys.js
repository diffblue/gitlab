import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import {
  tokenKeys,
  alternativeTokenKeys,
  conditions,
} from '~/filtered_search/issuable_filtered_search_token_keys';
import { __ } from '~/locale';
import {
  TOKEN_TITLE_EPIC,
  TOKEN_TITLE_ITERATION,
  TOKEN_TITLE_WEIGHT,
} from 'ee/vue_shared/components/filtered_search_bar/constants';

export const weightTokenKey = {
  formattedKey: TOKEN_TITLE_WEIGHT,
  key: 'weight',
  type: 'string',
  param: '',
  symbol: '',
  icon: 'weight',
  tag: 'number',
};

export const epicTokenKey = {
  formattedKey: TOKEN_TITLE_EPIC,
  key: 'epic',
  type: 'string',
  param: 'id',
  symbol: '&',
  icon: 'epic',
};

export const iterationTokenKey = {
  formattedKey: TOKEN_TITLE_ITERATION,
  key: 'iteration',
  type: 'string',
  param: 'title',
  symbol: '',
  icon: 'iteration',
};

export const weightConditions = [
  {
    url: 'weight=None',
    operator: '=',
    tokenKey: 'weight',
    value: __('None'),
  },
  {
    url: 'weight=Any',
    operator: '=',
    tokenKey: 'weight',
    value: __('Any'),
  },
  {
    url: 'not[weight]=None',
    operator: '!=',
    tokenKey: 'weight',
    value: __('None'),
  },
  {
    url: 'not[weight]=Any',
    operator: '!=',
    tokenKey: 'weight',
    value: __('Any'),
  },
];

export const epicConditions = [
  {
    url: 'epic_id=None',
    operator: '=',
    tokenKey: 'epic',
    value: __('None'),
  },
  {
    url: 'epic_id=Any',
    operator: '=',
    tokenKey: 'epic',
    value: __('Any'),
  },
  {
    url: 'not[epic_id]=None',
    operator: '!=',
    tokenKey: 'epic',
    value: __('None'),
  },
  {
    url: 'not[epic_id]=Any',
    operator: '!=',
    tokenKey: 'epic',
    value: __('Any'),
  },
];

export const iterationConditions = [
  {
    url: 'iteration_id=None',
    operator: '=',
    tokenKey: 'iteration',
    value: __('None'),
  },
  {
    url: 'iteration_id=Any',
    operator: '=',
    tokenKey: 'iteration',
    value: __('Any'),
  },
  {
    url: 'iteration_id=Current',
    operator: '=',
    tokenKey: 'iteration',
    value: __('Current'),
  },
  {
    url: 'not[iteration_id]=Current',
    operator: '!=',
    tokenKey: 'iteration',
    value: __('Current'),
  },
];

/**
 * Filter tokens for issues in EE.
 */
class IssuesFilteredSearchTokenKeysEE extends FilteredSearchTokenKeys {
  constructor() {
    const milestoneTokenKeyIndex = tokenKeys.findIndex((tk) => tk.key === 'milestone');
    tokenKeys.splice(milestoneTokenKeyIndex + 1, 0, iterationTokenKey);

    super([...tokenKeys, epicTokenKey, weightTokenKey], alternativeTokenKeys, [
      ...conditions,
      ...weightConditions,
      ...epicConditions,
      ...iterationConditions,
    ]);
  }

  /**
   * Changes assignee token to accept multiple values.
   */
  enableMultipleAssignees() {
    const assigneeTokenKey = this.tokenKeys.find((tk) => tk.key === 'assignee');

    // Add the original as an alternative token key
    this.tokenKeysWithAlternative.push({ ...assigneeTokenKey });

    assigneeTokenKey.type = 'array';
    assigneeTokenKey.param = 'username[]';
  }

  removeEpicToken() {
    this.removeTokensForKeys(epicTokenKey.key);
  }

  removeIterationToken() {
    this.removeTokensForKeys(iterationTokenKey.key);
  }
}

export default new IssuesFilteredSearchTokenKeysEE();
