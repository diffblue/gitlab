import FilteredSearchManager from 'ee_else_ce/filtered_search/filtered_search_manager';
import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import { historyPushState } from '~/lib/utils/common_utils';
import { queryToObject } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import issueAnalyticsStore from './stores';

const EXCLUDED_TOKENS = ['release'];

export default class FilteredSearchIssueAnalytics extends FilteredSearchManager {
  constructor() {
    const issuesAnalyticsTokenKeys = new FilteredSearchTokenKeys(
      IssuableFilteredSearchTokenKeys.tokenKeys.filter(({ key }) => !EXCLUDED_TOKENS.includes(key)), // release filter is not working with the Issues API at the moment
      IssuableFilteredSearchTokenKeys.alternativeTokenKeys,
      IssuableFilteredSearchTokenKeys.conditions,
    );

    super({
      page: 'issues_analytics',
      isGroupDecendent: true,
      stateFiltersSelector: '.issues-state-filters',
      isGroup: true,
      useDefaultState: false,
      filteredSearchTokenKeys: issuesAnalyticsTokenKeys,
      placeholder: __('Filter results...'),
    });

    this.isHandledAsync = true;
  }

  /**
   * Updates issue analytics store and window history
   * with filter path
   */
  updateObject = (path) => {
    historyPushState(path);

    const filters = queryToObject(path, { gatherArrays: true });
    issueAnalyticsStore.dispatch('issueAnalytics/setFilters', filters);
  };
}
