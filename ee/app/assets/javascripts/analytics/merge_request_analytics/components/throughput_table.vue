<script>
import {
  GlTableLite,
  GlLink,
  GlAvatarLink,
  GlAvatar,
  GlAvatarsInline,
  GlTooltipDirective,
  GlLoadingIcon,
  GlAlert,
  GlIcon,
  GlPagination,
} from '@gitlab/ui';
import { mapState } from 'vuex';
import { dateFormats } from '~/analytics/shared/constants';
import dateFormat from '~/lib/dateformat';
import { approximateDuration, differenceInSeconds } from '~/lib/utils/datetime_utility';
import { __, s__, n__ } from '~/locale';
import { filterToQueryObject } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import {
  THROUGHPUT_TABLE_STRINGS,
  MERGE_REQUEST_ID_PREFIX,
  LINE_CHANGE_SYMBOLS,
  ASSIGNEES_VISIBLE,
  AVATAR_SIZE,
  PER_PAGE,
  THROUGHPUT_TABLE_TEST_IDS,
  PIPELINE_STATUS_ICON_CLASSES,
} from '../constants';
import throughputTableQuery from '../graphql/queries/throughput_table.query.graphql';

const TH_TEST_ID = { 'data-testid': THROUGHPUT_TABLE_TEST_IDS.TABLE_HEADERS };

const initialPaginationState = {
  currentPage: 1,
  prevPageCursor: '',
  nextPageCursor: '',
  firstPageSize: PER_PAGE,
  lastPageSize: null,
};

export default {
  name: 'ThroughputTable',
  components: {
    GlTableLite,
    GlLink,
    GlAvatarLink,
    GlAvatar,
    GlAvatarsInline,
    GlLoadingIcon,
    GlAlert,
    GlIcon,
    GlPagination,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['fullPath'],
  tableHeaderFields: [
    {
      key: 'mr_details',
      label: s__('MergeRequestAnalytics|Merge Request'),
      tdClass: 'merge-request-analytics-td',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'date_merged',
      label: s__('MergeRequestAnalytics|Date Merged'),
      tdClass: 'merge-request-analytics-td',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'time_to_merge',
      label: s__('MergeRequestAnalytics|Time to merge'),
      tdClass: 'merge-request-analytics-td',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'milestone',
      label: s__('MergeRequestAnalytics|Milestone'),
      tdClass: 'merge-request-analytics-td',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'commits',
      label: __('Commits'),
      tdClass: 'merge-request-analytics-td',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'pipelines',
      label: s__('MergeRequestAnalytics|Pipelines'),
      tdClass: 'merge-request-analytics-td',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'line_changes',
      label: s__('MergeRequestAnalytics|Line changes'),
      tdClass: 'merge-request-analytics-td',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'assignees',
      label: s__('MergeRequestAnalytics|Assignees'),
      tdClass: 'merge-request-analytics-td',
      thAttr: TH_TEST_ID,
    },
  ],
  props: {
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
  },
  data() {
    return {
      throughputTableData: {},
      pagination: initialPaginationState,
      hasError: false,
    };
  },
  apollo: {
    throughputTableData: {
      query: throughputTableQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          startDate: dateFormat(this.startDate, dateFormats.isoDate),
          endDate: dateFormat(this.endDate, dateFormats.isoDate),
          firstPageSize: this.pagination.firstPageSize,
          lastPageSize: this.pagination.lastPageSize,
          prevPageCursor: this.pagination.prevPageCursor,
          nextPageCursor: this.pagination.nextPageCursor,
          ...this.options,
        };
      },
      update(data) {
        const { mergeRequests: { nodes: list = [], pageInfo = {} } = {} } = data.project || {};
        return {
          list,
          pageInfo,
        };
      },
      error() {
        this.hasError = true;
      },
      context: {
        isSingleRequest: true,
      },
    },
  },
  computed: {
    ...mapState('filters', {
      selectedSourceBranch: (state) => state.branches.source.selected,
      selectedTargetBranch: (state) => state.branches.target.selected,
      selectedMilestone: (state) => state.milestones.selected,
      selectedAuthor: (state) => state.authors.selected,
      selectedAssignee: (state) => state.assignees.selected,
      selectedLabelList: (state) => state.labels.selectedList,
    }),
    options() {
      const options = filterToQueryObject({
        sourceBranches: this.selectedSourceBranch,
        targetBranches: this.selectedTargetBranch,
        milestoneTitle: this.selectedMilestone,
        authorUsername: this.selectedAuthor,
        assigneeUsername: this.selectedAssignee,
        labels: this.selectedLabelList,
      });

      return {
        ...options,
        notLabels: options['not[labels]'],
        notMilestoneTitle: options['not[milestoneTitle]'],
      };
    },
    tableDataAvailable() {
      return this.throughputTableData.list?.length;
    },
    tableDataLoading() {
      return !this.hasError && this.$apollo.queries.throughputTableData.loading;
    },
    alertDetails() {
      return {
        class: this.hasError ? 'danger' : 'info',
        message: this.hasError
          ? THROUGHPUT_TABLE_STRINGS.ERROR_FETCHING_DATA
          : THROUGHPUT_TABLE_STRINGS.NO_DATA,
      };
    },
    prevPage() {
      return Math.max(this.pagination.currentPage - 1, 0);
    },
    nextPage() {
      return this.throughputTableData.pageInfo.hasNextPage ? this.pagination.currentPage + 1 : null;
    },
    showPaginationControls() {
      return Boolean(this.prevPage || this.nextPage);
    },
  },
  watch: {
    options() {
      this.resetPagination();
    },
  },
  methods: {
    formatMergeRequestId(id) {
      return `${MERGE_REQUEST_ID_PREFIX}${id}`;
    },
    formatLineChangeAdditions(value) {
      return `${LINE_CHANGE_SYMBOLS.ADDITIONS}${value}`;
    },
    formatLineChangeDeletions(value) {
      return `${LINE_CHANGE_SYMBOLS.DELETITIONS}${value}`;
    },
    formatDateMerged(value) {
      return dateFormat(value, dateFormats.isoDate);
    },
    computeTimeToMerge(createdAt, mergedAt) {
      return approximateDuration(differenceInSeconds(new Date(createdAt), new Date(mergedAt)));
    },
    pipelineStatusClass(value) {
      return PIPELINE_STATUS_ICON_CLASSES[value] === undefined
        ? PIPELINE_STATUS_ICON_CLASSES.default
        : PIPELINE_STATUS_ICON_CLASSES[value];
    },
    formatApprovalText(approvals) {
      return n__('%d Approval', '%d Approvals', approvals);
    },
    handlePageChange(page) {
      const { startCursor, endCursor } = this.throughputTableData.pageInfo;

      if (page > this.pagination.currentPage) {
        this.pagination = {
          ...initialPaginationState,
          nextPageCursor: endCursor,
          currentPage: page,
        };
      } else {
        this.pagination = {
          lastPageSize: PER_PAGE,
          firstPageSize: null,
          prevPageCursor: startCursor,
          currentPage: page,
        };
      }
    },
    resetPagination() {
      this.pagination = initialPaginationState;
    },
    hasPipelineNodes(item) {
      return item.pipelines?.nodes;
    },
    assigneesBadgeSrOnlyText(item) {
      return n__(
        '%d additional assignee',
        '%d additional assignees',
        item.assignees.nodes.length - this.$options.assigneesVisible,
      );
    },
  },
  assigneesVisible: ASSIGNEES_VISIBLE,
  avatarSize: AVATAR_SIZE,
  testIds: THROUGHPUT_TABLE_TEST_IDS,
};
</script>
<template>
  <gl-loading-icon v-if="tableDataLoading" size="lg" />
  <div v-else-if="tableDataAvailable">
    <gl-table-lite
      :fields="$options.tableHeaderFields"
      :items="throughputTableData.list"
      stacked="sm"
      thead-class="gl-bg-white gl-text-color-secondary gl-border-t-0 gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
    >
      <template #cell(mr_details)="{ item }">
        <div
          class="gl-display-flex gl-flex-direction-column gl-flex-grow-1"
          :data-testid="$options.testIds.MERGE_REQUEST_DETAILS"
        >
          <div class="merge-request-title gl-str-truncated">
            <gl-link
              :href="item.webUrl"
              target="_blank"
              class="gl-font-weight-bold gl-text-gray-900"
              >{{ item.title }}</gl-link
            >
            <ul class="horizontal-list gl-mb-0">
              <li class="gl-mr-3">{{ formatMergeRequestId(item.iid) }}</li>
              <li v-if="hasPipelineNodes(item) && item.pipelines.nodes.length" class="gl-mr-3">
                <gl-icon
                  :name="item.pipelines.nodes[0].detailedStatus.icon"
                  :class="pipelineStatusClass(item.pipelines.nodes[0].detailedStatus.icon)"
                />
              </li>
              <li
                class="gl-mr-3 gl-display-flex gl-align-items-center"
                :class="{ 'gl-opacity-5': !item.labels.count }"
                :data-testid="$options.testIds.LABEL_DETAILS"
              >
                <gl-icon name="label" class="gl-mr-1" /><span>{{ item.labels.count }}</span>
              </li>
              <li
                class="gl-mr-3 gl-display-flex gl-align-items-center"
                :class="{ 'gl-opacity-5': !item.userNotesCount }"
                :data-testid="$options.testIds.COMMENT_COUNT"
              >
                <gl-icon name="comments" class="gl-mr-2" /><span>{{ item.userNotesCount }}</span>
              </li>
              <li
                v-if="item.approvedBy.nodes.length"
                class="gl-text-green-500"
                :data-testid="$options.testIds.APPROVED"
              >
                <gl-icon name="approval" class="gl-mr-2" /><span>{{
                  formatApprovalText(item.approvedBy.nodes.length)
                }}</span>
              </li>
            </ul>
          </div>
        </div>
      </template>

      <template #cell(date_merged)="{ item }">
        <div :data-testid="$options.testIds.DATE_MERGED">{{ formatDateMerged(item.mergedAt) }}</div>
      </template>

      <template #cell(time_to_merge)="{ item }">
        <div :data-testid="$options.testIds.TIME_TO_MERGE">
          {{ computeTimeToMerge(item.createdAt, item.mergedAt) }}
        </div>
      </template>

      <template #cell(milestone)="{ item }">
        <div v-if="item.milestone" :data-testid="$options.testIds.MILESTONE">
          {{ item.milestone.title }}
        </div>
      </template>

      <template #cell(commits)="{ item }">
        <div :data-testid="$options.testIds.COMMITS">{{ item.commitCount }}</div>
      </template>

      <template #cell(pipelines)="{ item }">
        <div v-if="hasPipelineNodes(item)" :data-testid="$options.testIds.PIPELINES">
          {{ item.pipelines.nodes.length }}
        </div>
      </template>

      <template #cell(line_changes)="{ item }">
        <div :data-testid="$options.testIds.LINE_CHANGES">
          <span class="gl-font-weight-bold gl-text-green-500">{{
            formatLineChangeAdditions(item.diffStatsSummary.additions)
          }}</span>
          <span class="gl-font-weight-bold gl-text-red-500">{{
            formatLineChangeDeletions(item.diffStatsSummary.deletions)
          }}</span>
        </div>
      </template>

      <template #cell(assignees)="{ item }">
        <div :data-testid="$options.testIds.ASSIGNEES">
          <gl-avatars-inline
            :avatars="item.assignees.nodes"
            :avatar-size="$options.avatarSize"
            :max-visible="$options.assigneesVisible"
            :badge-sr-only-text="assigneesBadgeSrOnlyText(item)"
            collapsed
          >
            <template #avatar="{ avatar }">
              <gl-avatar-link
                v-gl-tooltip
                target="_blank"
                :href="avatar.webUrl"
                :title="avatar.name"
              >
                <gl-avatar :src="avatar.avatarUrl" :size="$options.avatarSize" />
              </gl-avatar-link>
            </template>
          </gl-avatars-inline>
        </div>
      </template>
    </gl-table-lite>
    <gl-pagination
      v-if="showPaginationControls"
      :value="pagination.currentPage"
      :prev-page="prevPage"
      :next-page="nextPage"
      align="center"
      class="gl-mt-3"
      @input="handlePageChange"
    />
  </div>
  <gl-alert v-else :variant="alertDetails.class" :dismissible="false" class="gl-mt-4">{{
    alertDetails.message
  }}</gl-alert>
</template>
