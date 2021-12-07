<script>
import { GlButton, GlIcon } from '@gitlab/ui';

import EpicsFilteredSearchMixin from 'ee/roadmap/mixins/filtered_search_mixin';

import createFlash from '~/flash';

import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';

import { IssuableListTabs, DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import { parsePikadayDate, dateInWords } from '~/lib/utils/datetime_utility';
import { s__, sprintf } from '~/locale';

import { EpicsSortOptions } from '../constants';
import groupEpics from '../queries/group_epics.query.graphql';

import EpicsListEmptyState from './epics_list_empty_state.vue';

export default {
  IssuableListTabs,
  EpicsSortOptions,
  defaultPageSize: DEFAULT_PAGE_SIZE,
  epicSymbol: '&',
  components: {
    GlButton,
    GlIcon,
    IssuableList,
    EpicsListEmptyState,
  },
  mixins: [EpicsFilteredSearchMixin],
  inject: [
    'canCreateEpic',
    'canBulkEditEpics',
    'page',
    'prev',
    'next',
    'initialState',
    'initialSortBy',
    'epicsCount',
    'epicNewPath',
    'groupFullPath',
    'groupLabelsPath',
    'groupMilestonesPath',
    'emptyStatePath',
    'isSignedIn',
  ],
  apollo: {
    epics: {
      query: groupEpics,
      variables() {
        const queryVariables = {
          groupPath: this.groupFullPath,
          state: this.currentState,
          isSignedIn: this.isSignedIn,
        };

        if (this.prevPageCursor) {
          queryVariables.prevPageCursor = this.prevPageCursor;
          queryVariables.lastPageSize = this.$options.defaultPageSize;
        } else if (this.nextPageCursor) {
          queryVariables.nextPageCursor = this.nextPageCursor;
          queryVariables.firstPageSize = this.$options.defaultPageSize;
        } else {
          queryVariables.firstPageSize = this.$options.defaultPageSize;
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
      update(data) {
        const epicsRoot = data.group?.epics;

        return {
          list: epicsRoot?.nodes || [],
          pageInfo: epicsRoot?.pageInfo || {},
        };
      },
      error(error) {
        createFlash({
          message: s__('Epics|Something went wrong while fetching epics list.'),
          captureError: true,
          error,
        });
      },
    },
  },
  props: {
    initialFilterParams: {
      type: Object,
      required: false,
      default: () => ({}),
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
      epics: {
        list: [],
        pageInfo: {},
      },
    };
  },
  computed: {
    epicsListLoading() {
      return this.$apollo.queries.epics.loading;
    },
    epicsListEmpty() {
      return !this.$apollo.queries.epics.loading && !this.epics.list.length;
    },
    showPaginationControls() {
      const { hasPreviousPage, hasNextPage } = this.epics.pageInfo;

      // This explicit check is necessary as both the variables
      // can also be `false` and we just want to ensure that they're present.
      if (hasPreviousPage !== undefined || hasNextPage !== undefined) {
        return Boolean(hasPreviousPage || hasNextPage);
      }
      return !this.epicsListEmpty;
    },
    previousPage() {
      return Math.max(this.currentPage - 1, 0);
    },
    nextPage() {
      const nextPage = this.currentPage + 1;
      return nextPage >
        Math.ceil(this.epicsCount[this.currentState] / this.$options.defaultPageSize)
        ? null
        : nextPage;
    },
  },
  methods: {
    epicReference(epic) {
      const reference = `${this.$options.epicSymbol}${epic.iid}`;
      if (epic.group.fullPath !== this.groupFullPath) {
        return `${epic.group.fullPath}${reference}`;
      }
      return reference;
    },
    epicTimeframe({ startDate, dueDate }) {
      const start = startDate ? parsePikadayDate(startDate) : null;
      const due = dueDate ? parsePikadayDate(dueDate) : null;

      if (startDate && dueDate) {
        const startDateInWords = dateInWords(
          start,
          true,
          start.getFullYear() === due.getFullYear(),
        );
        const dueDateInWords = dateInWords(due, true);

        return sprintf(s__('Epics|%{startDate} – %{dueDate}'), {
          startDate: startDateInWords,
          dueDate: dueDateInWords,
        });
      } else if (startDate && !dueDate) {
        return sprintf(s__('Epics|%{startDate} – No due date'), {
          startDate: dateInWords(start, true, false),
        });
      } else if (!startDate && dueDate) {
        return sprintf(s__('Epics|No start date – %{dueDate}'), {
          dueDate: dateInWords(due, true, false),
        });
      }
      return '';
    },
    fetchEpicsBy(propsName, propValue) {
      if (propsName === 'currentPage') {
        const { startCursor, endCursor } = this.epics.pageInfo;

        if (propValue > this.currentPage) {
          this.prevPageCursor = '';
          this.nextPageCursor = endCursor;
        } else {
          this.prevPageCursor = startCursor;
          this.nextPageCursor = '';
        }
      } else if (propsName === 'currentState') {
        this.currentPage = 1;
        this.prevPageCursor = '';
        this.nextPageCursor = '';
      }
      this[propsName] = propValue;
    },
    handleFilterEpics(filters) {
      this.filterParams = this.getFilterParams(filters);
    },
  },
};
</script>

<template>
  <issuable-list
    :namespace="groupFullPath"
    :tabs="$options.IssuableListTabs"
    :current-tab="currentState"
    :tab-counts="epicsCount"
    :search-input-placeholder="__('Search or filter results...')"
    :search-tokens="getFilteredSearchTokens({ supportsEpic: false })"
    :sort-options="$options.EpicsSortOptions"
    :initial-filter-value="getFilteredSearchValue()"
    :initial-sort-by="sortedBy"
    :issuables="epics.list"
    :issuables-loading="epicsListLoading"
    :show-pagination-controls="showPaginationControls"
    :show-discussions="true"
    :default-page-size="$options.defaultPageSize"
    :current-page="currentPage"
    :previous-page="previousPage"
    :next-page="nextPage"
    :url-params="urlParams"
    :issuable-symbol="$options.epicSymbol"
    recent-searches-storage-key="epics"
    @click-tab="fetchEpicsBy('currentState', $event)"
    @page-change="fetchEpicsBy('currentPage', $event)"
    @sort="fetchEpicsBy('sortedBy', $event)"
    @filter="handleFilterEpics"
  >
    <template v-if="canCreateEpic || canBulkEditEpics" #nav-actions>
      <gl-button v-if="canCreateEpic" category="primary" variant="success" :href="epicNewPath">{{
        __('New epic')
      }}</gl-button>
    </template>
    <template #reference="{ issuable }">
      <span class="issuable-reference">{{ epicReference(issuable) }}</span>
    </template>
    <template #timeframe="{ issuable }">
      <gl-icon name="calendar" />
      {{ epicTimeframe(issuable) }}
    </template>
    <template #empty-state>
      <epics-list-empty-state :current-state="currentState" :epics-count="epicsCount" />
    </template>
  </issuable-list>
</template>
