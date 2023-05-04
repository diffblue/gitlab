<script>
import { GlButton } from '@gitlab/ui';

import Api from '~/api';
import { createAlert } from '~/alert';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import axios from '~/lib/utils/axios_utils';
import { updateHistory, setUrlParams, queryToObject } from '~/lib/utils/url_utility';

import { s__ } from '~/locale';
import {
  FILTERED_SEARCH_TERM,
  OPERATORS_IS,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_LABEL,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_LABEL,
} from '~/vue_shared/components/filtered_search_bar/constants';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import LabelToken from '~/vue_shared/components/filtered_search_bar/tokens/label_token.vue';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';

import { testCaseTabs, availableSortOptions } from '../constants';
import projectTestCases from '../queries/project_test_cases.query.graphql';
import TestCaseListEmptyState from './test_case_list_empty_state.vue';

export default {
  name: 'TestCaseList',
  testCaseTabs,
  availableSortOptions,
  defaultPageSize: DEFAULT_PAGE_SIZE,
  components: {
    GlButton,
    IssuableList,
    TestCaseListEmptyState,
  },
  inject: [
    'canCreateTestCase',
    'hasScopedLabelsFeature',
    'initialState',
    'page',
    'prev',
    'next',
    'initialSortBy',
    'projectFullPath',
    'projectLabelsPath',
    'testCaseNewPath',
  ],
  props: {
    initialFilterParams: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  apollo: {
    project: {
      query: projectTestCases,
      variables() {
        const queryVariables = {
          projectPath: this.projectFullPath,
          state: this.currentState,
          types: ['TEST_CASE'],
        };

        if (this.prevPageCursor) {
          queryVariables.prevPageCursor = this.prevPageCursor;
          queryVariables.lastPageSize = DEFAULT_PAGE_SIZE;
        } else if (this.nextPageCursor) {
          queryVariables.nextPageCursor = this.nextPageCursor;
          queryVariables.firstPageSize = DEFAULT_PAGE_SIZE;
        } else {
          queryVariables.firstPageSize = DEFAULT_PAGE_SIZE;
        }

        if (this.sortedBy) {
          queryVariables.sortBy = this.sortedBy;
        }

        if (Object.keys(this.filterParams).length) {
          Object.assign(queryVariables, {
            ...this.filterParams,
          });
        }

        return queryVariables;
      },
      error(error) {
        createAlert({
          message: s__('TestCases|Something went wrong while fetching test cases list.'),
          captureError: true,
          error,
        });
      },
    },
  },
  data() {
    return {
      currentState: this.initialState,
      currentPage: this.page,
      prevPageCursor: this.prev,
      nextPageCursor: this.next,
      filterParams: this.initialFilterParams,
      sortedBy: this.initialSortBy,
      project: {
        issueStatusCounts: {},
        issues: {},
      },
    };
  },
  computed: {
    testCases() {
      return {
        list: this.project?.issues?.nodes || [],
        pageInfo: this.project?.issues?.pageInfo || {},
      };
    },
    testCasesCount() {
      const { opened = 0, closed = 0, all = 0 } = this.project?.issueStatusCounts || {};
      return {
        opened,
        closed,
        all,
      };
    },
    testCaseListLoading() {
      return this.$apollo.queries.project.loading;
    },
    testCaseListEmpty() {
      return !this.$apollo.queries.project.loading && !this.testCases.list.length;
    },
    showPaginationControls() {
      const { hasPreviousPage, hasNextPage } = this.testCases.pageInfo;

      // This explicit check is necessary as both the variables
      // can also be `false` and we just want to ensure that they're present.
      if (hasPreviousPage !== undefined || hasNextPage !== undefined) {
        return Boolean(hasPreviousPage || hasNextPage);
      }
      return !this.testCaseListEmpty;
    },
    previousPage() {
      return Math.max(this.currentPage - 1, 0);
    },
    nextPage() {
      const nextPage = this.currentPage + 1;
      return nextPage > Math.ceil(this.testCasesCount[this.currentState] / DEFAULT_PAGE_SIZE)
        ? null
        : nextPage;
    },
  },
  methods: {
    updateUrl() {
      const queryParams = queryToObject(window.location.search, { gatherArrays: true });
      const { authorUsername, labelName, search } = this.filterParams || {};
      const { currentState, sortedBy, currentPage, prevPageCursor, nextPageCursor } = this;

      queryParams.state = currentState;
      queryParams.sort = sortedBy;
      queryParams.page = currentPage || 1;

      // Only keep params that have any values.
      if (prevPageCursor) {
        queryParams.prev = prevPageCursor;
      } else {
        delete queryParams.prev;
      }

      if (nextPageCursor) {
        queryParams.next = nextPageCursor;
      } else {
        delete queryParams.next;
      }

      if (authorUsername) {
        queryParams.author_username = authorUsername;
      } else {
        delete queryParams.author_username;
      }

      delete queryParams.label_name;
      if (labelName?.length) {
        queryParams['label_name[]'] = labelName;
      }

      if (search) {
        queryParams.search = search;
      } else {
        delete queryParams.search;
      }

      // We want to replace the history state so that back button
      // correctly reloads the page with previous URL.
      updateHistory({
        url: setUrlParams(queryParams, window.location.href, true),
        title: document.title,
        replace: true,
      });
    },
    getFilteredSearchTokens() {
      return [
        {
          type: TOKEN_TYPE_AUTHOR,
          icon: 'user',
          title: TOKEN_TITLE_AUTHOR,
          unique: true,
          symbol: '@',
          token: UserToken,
          operators: OPERATORS_IS,
          fetchPath: this.projectFullPath,
          fetchUsers: Api.projectUsers.bind(Api),
        },
        {
          type: TOKEN_TYPE_LABEL,
          icon: 'labels',
          title: TOKEN_TITLE_LABEL,
          unique: false,
          symbol: '~',
          token: LabelToken,
          operators: OPERATORS_IS,
          fetchLabels: (search = '') => {
            const params = {
              include_ancestor_groups: true,
            };

            if (search) {
              params.search = search;
            }

            return axios.get(this.projectLabelsPath, {
              params,
            });
          },
        },
      ];
    },
    getFilteredSearchValue() {
      const { authorUsername, labelName, search } = this.filterParams || {};
      const filteredSearchValue = [];

      if (authorUsername) {
        filteredSearchValue.push({
          type: TOKEN_TYPE_AUTHOR,
          value: { data: authorUsername },
        });
      }

      if (labelName?.length) {
        filteredSearchValue.push(
          ...labelName.map((label) => ({
            type: TOKEN_TYPE_LABEL,
            value: { data: label },
          })),
        );
      }

      if (search) {
        filteredSearchValue.push(search);
      }

      return filteredSearchValue;
    },
    handleClickTab(stateName) {
      this.currentState = stateName;

      this.updateUrl();
    },
    handlePageChange(page) {
      const { startCursor, endCursor } = this.testCases.pageInfo;

      if (page > this.currentPage) {
        this.prevPageCursor = '';
        this.nextPageCursor = endCursor;
      } else {
        this.prevPageCursor = startCursor;
        this.nextPageCursor = '';
      }

      this.currentPage = page;

      this.updateUrl();
    },
    handleFilterTestCases(filters = []) {
      const filterParams = {};
      const labels = [];

      filters.forEach((filter) => {
        switch (filter.type) {
          case TOKEN_TYPE_AUTHOR:
            filterParams.authorUsername = filter.value.data;
            break;
          case TOKEN_TYPE_LABEL:
            labels.push(filter.value.data);
            break;
          case FILTERED_SEARCH_TERM:
            if (filter.value.data) {
              filterParams.search = filter.value.data;
            }
            break;
          default:
            break;
        }
      });

      if (labels.length) {
        filterParams.labelName = labels;
      }

      this.filterParams = filterParams;

      this.updateUrl();
    },
    handleSortTestCases(sortedBy) {
      this.sortedBy = sortedBy;

      this.updateUrl();
    },
  },
};
</script>

<template>
  <issuable-list
    :namespace="projectFullPath"
    :tabs="$options.testCaseTabs"
    :tab-counts="testCasesCount"
    :current-tab="currentState"
    :search-input-placeholder="s__('TestCases|Search test cases')"
    :search-tokens="getFilteredSearchTokens()"
    :sort-options="$options.availableSortOptions"
    :has-scoped-labels-feature="hasScopedLabelsFeature"
    :initial-filter-value="getFilteredSearchValue()"
    :initial-sort-by="sortedBy"
    :issuables="testCases.list"
    :issuables-loading="testCaseListLoading"
    :show-pagination-controls="showPaginationControls"
    :default-page-size="$options.defaultPageSize"
    :current-page="currentPage"
    :previous-page="previousPage"
    :next-page="nextPage"
    recent-searches-storage-key="test_cases"
    issuable-symbol="#"
    @click-tab="handleClickTab"
    @page-change="handlePageChange"
    @filter="handleFilterTestCases"
    @sort="handleSortTestCases"
  >
    <template v-if="canCreateTestCase" #nav-actions>
      <gl-button :href="testCaseNewPath" category="primary" variant="confirm">{{
        s__('TestCases|New test case')
      }}</gl-button>
    </template>
    <template #empty-state>
      <test-case-list-empty-state
        :current-state="currentState"
        :test-cases-count="testCasesCount"
      />
    </template>
  </issuable-list>
</template>
