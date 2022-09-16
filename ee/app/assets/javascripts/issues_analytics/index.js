import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { queryToObject } from '~/lib/utils/url_utility';
import IssuesAnalytics from './components/issues_analytics.vue';
import store from './stores';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default () => {
  const el = document.querySelector('#js-issues-analytics');
  const filterBlockEl = document.querySelector('.issues-filters');

  if (!el) return null;

  const {
    fullPath,
    type,
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
    name: 'IssuesAnalytics',
    apolloProvider,
    store,
    provide: {
      fullPath,
      type,
    },
    render: (createElement) =>
      createElement(IssuesAnalytics, {
        props: {
          endpoint,
          filterBlockEl,
          noDataEmptyStateSvgPath,
          filtersEmptyStateSvgPath,
          issuesApiEndpoint,
          issuesPageEndpoint,
        },
      }),
  });
};
