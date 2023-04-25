<script>
import { GlButton, GlIcon, GlLink, GlSprintf, GlAlert } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import SafeHtml from '~/vue_shared/directives/safe_html';

import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import {
  issuableListTabs,
  availableSortOptions,
  DEFAULT_PAGE_SIZE,
} from '~/vue_shared/issuable/list/constants';
import { STATUS_ALL, STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import { i18n } from '~/issues/list/constants';
import {
  FILTERED_SEARCH_TERM,
  OPERATORS_IS,
  TOKEN_TITLE_LABEL,
  TOKEN_TYPE_LABEL,
} from '~/vue_shared/components/filtered_search_bar/constants';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';

import ExternalIssuesListEmptyState from './external_issues_list_empty_state.vue';

export default {
  name: 'ExternalIssuesList',
  issuableListTabs,
  availableSortOptions,
  defaultPageSize: DEFAULT_PAGE_SIZE,
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
    GlAlert,
    IssuableList,
    ExternalIssuesListEmptyState,
  },
  directives: {
    SafeHtml,
  },
  inject: [
    'initialState',
    'initialSortBy',
    'page',
    'issuesFetchPath',
    'projectFullPath',
    'issueCreateUrl',
    'getIssuesQuery',
    'externalIssuesLogo',
    'externalIssueTrackerName',
    'searchInputPlaceholderText',
    'recentSearchesStorageKey',
    'createNewIssueText',
  ],
  props: {
    initialFilterParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      issues: [],
      totalIssues: 0,
      currentState: this.initialState,
      filterParams: this.initialFilterParams,
      sortedBy: this.initialSortBy,
      currentPage: this.page,
      issuesCount: {
        [STATUS_OPEN]: 0,
        [STATUS_CLOSED]: 0,
        [STATUS_ALL]: 0,
      },
      errorMessage: null,
    };
  },
  computed: {
    issuesListLoading() {
      return this.$apollo.queries.externalIssues.loading;
    },
    showPaginationControls() {
      return Boolean(!this.issuesListLoading && this.issues.length && this.totalIssues > 1);
    },
    hasFiltersApplied() {
      return Boolean(this.filterParams.search || this.filterParams.labels);
    },
    urlParams() {
      return {
        'labels[]': this.filterParams.labels,
        search: this.filterParams.search,
        ...(this.currentPage === 1 ? {} : { page: this.currentPage }),
        ...(this.sortedBy === this.initialSortBy ? {} : { sort: this.sortedBy }),
        ...(this.currentState === this.initialState ? {} : { state: this.currentState }),
      };
    },
  },
  apollo: {
    externalIssues: {
      query() {
        return this.getIssuesQuery;
      },
      variables() {
        return {
          issuesFetchPath: this.issuesFetchPath,
          labels: this.filterParams.labels,
          page: this.currentPage,
          search: this.filterParams.search,
          sort: this.sortedBy,
          state: this.currentState,
        };
      },
      result({ data, error }) {
        // let error() callback handle errors
        if (error) {
          return;
        }

        const { pageInfo, nodes, errors } = data?.externalIssues ?? {};
        if (errors?.length > 0) {
          this.onExternalIssuesQueryError(new Error(errors[0]));
          return;
        }

        this.issues = nodes;
        this.currentPage = pageInfo.page;
        this.totalIssues = pageInfo.total;
        this.issuesCount[this.currentState] = nodes.length;
      },
      error(error) {
        this.onExternalIssuesQueryError(error, i18n.errorFetchingIssues);
      },
    },
  },
  methods: {
    getFilteredSearchTokens() {
      return [
        {
          type: TOKEN_TYPE_LABEL,
          icon: 'labels',
          symbol: '~',
          title: TOKEN_TITLE_LABEL,
          unique: false,
          token: LabelToken,
          operators: OPERATORS_IS,
          defaultLabels: [],
          suggestionsDisabled: true,
          fetchLabels: () => {
            return Promise.resolve([]);
          },
        },
      ];
    },
    getFilteredSearchValue() {
      const { labels, search } = this.filterParams || {};
      const filteredSearchValue = [];

      if (labels) {
        filteredSearchValue.push(
          ...labels.map((label) => ({
            type: TOKEN_TYPE_LABEL,
            value: { data: label },
          })),
        );
      }

      if (search) {
        filteredSearchValue.push({
          type: FILTERED_SEARCH_TERM,
          value: {
            data: search,
          },
        });
      }

      return filteredSearchValue;
    },
    onExternalIssuesQueryError(error, message) {
      this.errorMessage = message || error.message;

      Sentry.captureException(error);
    },
    onIssuableListClickTab(selectedIssueState) {
      this.currentPage = 1;
      this.currentState = selectedIssueState;
    },
    onIssuableListPageChange(selectedPage) {
      this.currentPage = selectedPage;
    },
    onIssuableListSort(selectedSort) {
      this.currentPage = 1;
      this.sortedBy = selectedSort;
    },
    onIssuableListFilter(filters = []) {
      const filterParams = {};
      const labels = [];
      const plainText = [];

      filters.forEach((filter) => {
        if (!filter.value.data) return;

        switch (filter.type) {
          case TOKEN_TYPE_LABEL:
            labels.push(filter.value.data);
            break;
          case FILTERED_SEARCH_TERM:
            plainText.push(filter.value.data);
            break;
          default:
            break;
        }
      });

      if (plainText.length) {
        filterParams.search = plainText.join(' ');
      }

      if (labels.length) {
        filterParams.labels = labels;
      }

      this.filterParams = filterParams;
    },
  },
  alertSafeHtmlConfig: { ALLOW_TAGS: ['a'] },
};
</script>

<template>
  <gl-alert v-if="errorMessage" class="gl-mt-3" variant="danger" :dismissible="false">
    <span v-safe-html:[$options.alertSafeHtmlConfig]="errorMessage"></span>
  </gl-alert>
  <issuable-list
    v-else
    :namespace="projectFullPath"
    :tabs="$options.issuableListTabs"
    :current-tab="currentState"
    :search-input-placeholder="searchInputPlaceholderText"
    :search-tokens="getFilteredSearchTokens()"
    :sort-options="$options.availableSortOptions"
    :initial-filter-value="getFilteredSearchValue()"
    :initial-sort-by="sortedBy"
    :issuables="issues"
    :issuables-loading="issuesListLoading"
    :show-pagination-controls="showPaginationControls"
    :default-page-size="$options.defaultPageSize"
    :total-items="totalIssues"
    :current-page="currentPage"
    :previous-page="currentPage - 1"
    :next-page="currentPage + 1"
    :url-params="urlParams"
    label-filter-param="labels"
    :recent-searches-storage-key="recentSearchesStorageKey"
    @click-tab="onIssuableListClickTab"
    @page-change="onIssuableListPageChange"
    @sort="onIssuableListSort"
    @filter="onIssuableListFilter"
  >
    <template #nav-actions>
      <gl-button :href="issueCreateUrl" target="_blank" class="gl-my-5">
        {{ createNewIssueText }}
        <gl-icon name="external-link" />
      </gl-button>
    </template>
    <template #reference="{ issuable }">
      <span v-safe-html="externalIssuesLogo" class="svg-container logo-container"></span>
      <span v-if="issuable">
        {{ issuable.references ? issuable.references.relative : issuable.id }}
      </span>
    </template>
    <template #author="{ author }">
      <gl-sprintf :message="`%{authorName} in ${externalIssueTrackerName}`">
        <template #authorName>
          <gl-link class="author-link js-user-link" target="_blank" :href="author.webUrl">
            {{ author.name }}
          </gl-link>
        </template>
      </gl-sprintf>
    </template>
    <template #status="{ issuable }">
      <template v-if="issuable"> {{ issuable.status }} </template>
    </template>
    <template #empty-state>
      <external-issues-list-empty-state
        :current-state="currentState"
        :issues-count="issuesCount"
        :has-filters-applied="hasFiltersApplied"
      />
    </template>
  </issuable-list>
</template>
