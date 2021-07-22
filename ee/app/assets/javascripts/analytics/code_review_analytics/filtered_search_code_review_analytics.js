import FilteredSearchManager from 'ee_else_ce/filtered_search/filtered_search_manager';
import { queryToObject } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import CodeReviewAnalyticsFilteredSearchTokenKeys from './code_review_analytics_filtered_search_token_keys';
import store from './store';
import transformFilters from './utils';

export default class FilteredSearchCodeReviewAnalytics extends FilteredSearchManager {
  constructor() {
    super({
      page: 'code_reviews',
      isGroupDecendent: true,
      stateFiltersSelector: '.issues-state-filters',
      isGroup: true,
      useDefaultState: false,
      filteredSearchTokenKeys: CodeReviewAnalyticsFilteredSearchTokenKeys,
      placeholder: __('Filter results...'),
    });

    this.isHandledAsync = true;
  }

  /**
   * Updates filters in code review analytics store
   */
  updateObject = (path) => {
    const filters = queryToObject(path, { gatherArrays: true });
    const { selectedLabels: selectedLabelList, selectedMilestone } = transformFilters(filters);

    store.dispatch('filters/setFilters', {
      selectedLabelList,
      selectedMilestone,
    });
  };
}
