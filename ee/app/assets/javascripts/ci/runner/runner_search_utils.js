import {
  fromUrlQueryToSearch as ceFromUrlQueryToSearch,
  fromSearchToUrl as ceFromSearchToUrl,
  fromSearchToVariables as ceFromSearchToVariables,
} from '~/ci/runner/runner_search_utils';
import { setUrlParams } from '~/lib/utils/url_utility';
import {
  filterToQueryObject,
  processFilters,
  urlQueryToFilter,
  prepareTokens,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import { PARAM_KEY_SEARCH } from '~/ci/runner/constants';
import { PARAM_KEY_UPGRADE_STATUS } from './constants';

/* eslint-disable import/export */

// Override following functions in EE, export the rest
export * from '~/ci/runner/runner_search_utils';

export const fromUrlQueryToSearch = (query = window.location.search) => {
  const ceSearch = ceFromUrlQueryToSearch(query);
  const ceFilters = ceSearch.filters;

  const eeFilters = prepareTokens(
    urlQueryToFilter(query, {
      filterNamesAllowList: [PARAM_KEY_UPGRADE_STATUS],
    }),
  );

  return {
    ...ceSearch,
    filters: [...ceFilters, ...eeFilters],
  };
};

export const fromSearchToUrl = (search, url = window.location.href) => {
  const ceUrl = ceFromSearchToUrl(search, url);

  const eeFilters = search.filters.filter(({ type }) => type === PARAM_KEY_UPGRADE_STATUS);
  const eeFilterParams = {
    // Defaults, required to set empty params that don't get set
    [PARAM_KEY_UPGRADE_STATUS]: [],
    // Adds current filters
    ...filterToQueryObject(processFilters(eeFilters)),
  };

  return setUrlParams(eeFilterParams, ceUrl, false, true, true);
};

export const fromSearchToVariables = (search) => {
  const ceVariables = ceFromSearchToVariables(search);

  const queryObj = filterToQueryObject(processFilters(search.filters), {
    filteredSearchTermKey: PARAM_KEY_SEARCH,
  });

  const eeVariables = {
    upgradeStatus: queryObj[PARAM_KEY_UPGRADE_STATUS]?.[0],
  };
  return { ...ceVariables, ...eeVariables };
};

/* eslint-enable import/export */
