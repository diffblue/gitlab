<script>
import jiraLogo from '@gitlab/svgs/dist/illustrations/logos/jira.svg';
import { GlButton, GlIcon, GlLink, GlSprintf, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';

import createFlash from '~/flash';
import IssuableList from '~/issuable_list/components/issuable_list_root.vue';
import {
  IssuableStates,
  IssuableListTabs,
  AvailableSortOptions,
  DEFAULT_PAGE_SIZE,
} from '~/issuable_list/constants';
import { ISSUES_LIST_FETCH_ERROR } from '../constants';
import getJiraIssuesQuery from '../graphql/queries/get_jira_issues.query.graphql';
import JiraIssuesListEmptyState from './jira_issues_list_empty_state.vue';

export default {
  name: 'JiraIssuesList',
  IssuableListTabs,
  AvailableSortOptions,
  defaultPageSize: DEFAULT_PAGE_SIZE,
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlSprintf,
    IssuableList,
    JiraIssuesListEmptyState,
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
      jiraLogo,
      issues: [],
      totalIssues: 0,
      currentState: this.initialState,
      filterParams: this.initialFilterParams,
      sortedBy: this.initialSortBy,
      currentPage: this.page,
      issuesCount: {
        [IssuableStates.Opened]: 0,
        [IssuableStates.Closed]: 0,
        [IssuableStates.All]: 0,
      },
    };
  },
  computed: {
    issuesListLoading() {
      return this.$apollo.queries.jiraIssues.loading;
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
    jiraIssues: {
      query: getJiraIssuesQuery,
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

        const { pageInfo, nodes, errors } = data?.jiraIssues ?? {};
        if (errors?.length > 0) {
          this.onJiraIssuesQueryError(new Error(errors[0]));
          return;
        }

        this.issues = nodes;
        this.currentPage = pageInfo.page;
        this.totalIssues = pageInfo.total;
        this.issuesCount[this.currentState] = nodes.length;
      },
      error() {
        this.onJiraIssuesQueryError(new Error(ISSUES_LIST_FETCH_ERROR));
      },
    },
  },
  methods: {
    getFilteredSearchValue() {
      return [
        {
          type: 'filtered-search-term',
          value: {
            data: this.filterParams.search || '',
          },
        },
      ];
    },
    onJiraIssuesQueryError(error) {
      createFlash({
        message: error.message,
        captureError: true,
        error,
      });
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
      const plainText = [];

      filters.forEach((filter) => {
        if (filter.type === 'filtered-search-term' && filter.value.data) {
          plainText.push(filter.value.data);
        }
      });

      if (plainText.length) {
        filterParams.search = plainText.join(' ');
      }

      this.filterParams = filterParams;
    },
  },
};
</script>

<template>
  <issuable-list
    :namespace="projectFullPath"
    :tabs="$options.IssuableListTabs"
    :current-tab="currentState"
    :search-input-placeholder="s__('Integrations|Search Jira issues')"
    :search-tokens="[]"
    :sort-options="$options.AvailableSortOptions"
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
    recent-searches-storage-key="jira_issues"
    @click-tab="onIssuableListClickTab"
    @page-change="onIssuableListPageChange"
    @sort="onIssuableListSort"
    @filter="onIssuableListFilter"
  >
    <template #nav-actions>
      <gl-button :href="issueCreateUrl" target="_blank" class="gl-my-5">
        {{ s__('Integrations|Create new issue in Jira') }}
        <gl-icon name="external-link" />
      </gl-button>
    </template>
    <template #reference="{ issuable }">
      <span v-safe-html="jiraLogo" class="svg-container jira-logo-container"></span>
      <span v-if="issuable">{{ issuable.references.relative }}</span>
    </template>
    <template #author="{ author }">
      <gl-sprintf message="%{authorName} in Jira">
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
      <jira-issues-list-empty-state
        :current-state="currentState"
        :issues-count="issuesCount"
        :has-filters-applied="hasFiltersApplied"
      />
    </template>
  </issuable-list>
</template>
