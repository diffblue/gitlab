import Vue from 'vue';
import { queryToObject } from '~/lib/utils/url_utility';
import IssuesAnalytics from './components/issues_analytics.vue';
import store from './stores';

export default () => {
  const el = document.querySelector('#js-issues-analytics');
  const filterBlockEl = document.querySelector('.issues-filters');

  if (!el) return null;

  const {
    endpoint,
    noDataEmptyStateSvgPath,
    filtersEmptyStateSvgPath,
    issuesApiEndpoint,
    issuesPageEndpoint,
  } = el.dataset;

  // Set default filters from URL
  const filters = queryToObject(window.location.search, { gatherArrays: true });
  store.dispatch('issueAnalytics/setFilters', filters);

  return new Vue({
    el,
    store,
    components: {
      IssuesAnalytics,
    },
    render(createElement) {
      return createElement('issues-analytics', {
        props: {
          endpoint,
          filterBlockEl,
          noDataEmptyStateSvgPath,
          filtersEmptyStateSvgPath,
          issuesApiEndpoint,
          issuesPageEndpoint,
        },
      });
    },
  });
};
