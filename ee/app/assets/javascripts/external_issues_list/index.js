import Vue from 'vue';

import { STATUS_OPEN } from '~/issues/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { queryToObject } from '~/lib/utils/url_utility';

import ExternalIssuesListApp from './components/external_issues_list_root.vue';
import getApolloProvider from './graphql';

export default function externalIssuesListFactory({
  provides: {
    getIssuesQuery,
    externalIssuesLogo,
    externalIssueTrackerName,
    searchInputPlaceholderText,
    recentSearchesStorageKey,
    createNewIssueText,
    emptyStateNoIssueText,
  },
  externalIssuesQueryResolver,
}) {
  return function initExternalIssuesList({ mountPointSelector }) {
    const mountPointEl = document.querySelector(mountPointSelector);

    if (!mountPointEl) {
      return null;
    }

    const {
      page = 1,
      initialState = STATUS_OPEN,
      initialSortBy = 'created_desc',
    } = mountPointEl.dataset;

    const initialFilterParams = Object.assign(
      convertObjectPropsToCamelCase(
        queryToObject(window.location.search.substring(1), { gatherArrays: true }),
        {
          dropKeys: ['scope', 'utf8', 'state', 'sort'], // These keys are unsupported/unnecessary
        },
      ),
    );

    return new Vue({
      el: mountPointEl,
      name: 'ExternalIssuesListRoot',
      provide: {
        ...mountPointEl.dataset,
        page: parseInt(page, 10),
        initialState,
        initialSortBy,
        getIssuesQuery,
        externalIssuesLogo,
        externalIssueTrackerName,
        searchInputPlaceholderText,
        recentSearchesStorageKey,
        createNewIssueText,
        emptyStateNoIssueText,
      },
      apolloProvider: getApolloProvider(externalIssuesQueryResolver),
      render: (createElement) =>
        createElement(ExternalIssuesListApp, {
          props: {
            initialFilterParams,
          },
        }),
    });
  };
}
