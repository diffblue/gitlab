import FilteredSearchManager from 'ee_else_ce/filtered_search/filtered_search_manager';
import IssuableFilteredSearchTokenKeys from 'ee_else_ce/filtered_search/issuable_filtered_search_token_keys';
import FilteredSearchTokenKeys from '~/filtered_search/filtered_search_token_keys';
import {
  TOKEN_TYPE_EPIC,
  TOKEN_TYPE_ITERATION,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_RELEASE,
  TOKEN_TYPE_WEIGHT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { historyPushState } from '~/lib/utils/common_utils';
import { queryToObject } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import issueAnalyticsStore from './stores';

export default class FilteredSearchIssueAnalytics extends FilteredSearchManager {
  constructor({ hasIssuesCompletedFeature = false }) {
    let excludedTokenKeys = [TOKEN_TYPE_RELEASE];

    if (gon.features?.issuesCompletedAnalyticsFeatureFlag && hasIssuesCompletedFeature) {
      // these tokens will be excluded until https://gitlab.com/gitlab-org/gitlab/-/issues/419925 is completed
      const issuesCompletedExcludedTokenKeys = [
        TOKEN_TYPE_EPIC,
        TOKEN_TYPE_ITERATION,
        TOKEN_TYPE_MY_REACTION,
        TOKEN_TYPE_WEIGHT,
      ];

      excludedTokenKeys = [...excludedTokenKeys, ...issuesCompletedExcludedTokenKeys];
    }

    const issuesAnalyticsTokenKeys = new FilteredSearchTokenKeys(
      IssuableFilteredSearchTokenKeys.tokenKeys.filter(
        ({ key }) => !excludedTokenKeys.includes(key),
      ),
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
  // eslint-disable-next-line class-methods-use-this
  updateObject = (path) => {
    historyPushState(path);

    const filters = queryToObject(path, { gatherArrays: true });
    issueAnalyticsStore.dispatch('issueAnalytics/setFilters', filters);
  };
}
