<script>
import {
  GlTableLite,
  GlLoadingIcon,
  GlLink,
  GlIcon,
  GlAvatarLink,
  GlAvatar,
  GlAvatarsInline,
  GlTooltipDirective,
  GlPopover,
  GlLabel,
} from '@gitlab/ui';

import { createAlert } from '~/alert';
import { WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { getDayDifference } from '~/lib/utils/datetime_utility';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { s__, n__, __ } from '~/locale';
import issueAnalyticsQuery from '../graphql/queries/issues_analytics.query.graphql';

const SYMBOL = {
  ISSUE: '#',
  EPIC: '&',
};
const MAX_VISIBLE_ASSIGNEES = 2;

const TH_TEST_ID = { 'data-testid': 'header' };

const ISSUE_STATE_I18N_MAP = {
  opened: __('Opened'),
  closed: __('Closed'),
};

export default {
  name: 'IssuesAnalyticsTable',
  components: {
    GlTableLite,
    GlLoadingIcon,
    GlLink,
    GlIcon,
    GlAvatarLink,
    GlAvatar,
    GlAvatarsInline,
    GlPopover,
    GlLabel,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['fullPath', 'type'],
  props: {
    endpoints: {
      type: Object,
      required: true,
    },
  },
  tableHeaderFields: [
    {
      key: 'issueDetails',
      label: s__('IssueAnalytics|Issue'),
      tdClass: 'issues-analytics-td',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'createdAt',
      label: s__('IssueAnalytics|Age'),
      class: 'gl-text-left',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'state',
      label: s__('IssueAnalytics|Status'),
      thAttr: TH_TEST_ID,
    },
    {
      key: 'milestone',
      label: s__('IssueAnalytics|Milestone'),
      thAttr: TH_TEST_ID,
    },
    {
      key: 'iteration',
      label: s__('IssueAnalytics|Iteration'),
      thAttr: TH_TEST_ID,
    },
    {
      key: 'weight',
      label: s__('IssueAnalytics|Weight'),
      class: 'gl-text-right',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'dueDate',
      label: s__('IssueAnalytics|Due date'),
      class: 'gl-text-left',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'assignees',
      label: s__('IssueAnalytics|Assignees'),
      class: 'gl-text-left',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'author',
      label: s__('IssueAnalytics|Created by'),
      class: 'gl-text-left',
      thAttr: TH_TEST_ID,
    },
  ],
  data() {
    return {
      issues: [],
    };
  },
  apollo: {
    issues: {
      query: issueAnalyticsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          isGroup: this.type === WORKSPACE_GROUP,
          isProject: this.type === WORKSPACE_PROJECT,
        };
      },
      update(data) {
        return data.project?.issues.nodes || data.group?.issues.nodes || [];
      },
      error() {
        createAlert({
          message: s__('IssueAnalytics|Failed to load issues. Please try again.'),
        });
      },
    },
  },
  computed: {
    isLoading() {
      return Boolean(this.$apollo.queries.issues?.loading);
    },
    shouldDisplayTable() {
      return this.issues.length;
    },
  },
  methods: {
    formatAge(date) {
      return n__('%d day', '%d days', getDayDifference(new Date(date), new Date(Date.now())));
    },
    formatStatus(status) {
      return ISSUE_STATE_I18N_MAP[status] || capitalizeFirstCharacter(status);
    },
    formatIssueId(id) {
      return `${SYMBOL.ISSUE}${id}`;
    },
    formatEpicId(id) {
      return `${SYMBOL.EPIC}${id}`;
    },
    labelTarget(name) {
      return mergeUrlParams({ 'label_name[]': name }, this.endpoints.issuesPage);
    },
    assigneesBadgeSrOnlyText(assignees) {
      return n__(
        '%d additional assignee',
        '%d additional assignees',
        assignees.length - MAX_VISIBLE_ASSIGNEES,
      );
    },
  },
  avatarSize: 24,
  MAX_VISIBLE_ASSIGNEES,
};
</script>
<template>
  <gl-loading-icon v-if="isLoading" size="lg" />
  <gl-table-lite
    v-else-if="shouldDisplayTable"
    :fields="$options.tableHeaderFields"
    :items="issues"
    stacked="sm"
    striped
  >
    <template #cell(issueDetails)="{ item }">
      <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1" data-testid="detailsCol">
        <div class="issue-title str-truncated">
          <gl-link :href="item.webUrl" target="_blank" class="gl-font-weight-bold text-plain">{{
            item.title
          }}</gl-link>
        </div>
        <ul class="horizontal-list list-items-separated gl-mb-0">
          <li>{{ formatIssueId(item.iid) }}</li>
          <li v-if="item.epic">{{ formatEpicId(item.epic.iid) }}</li>
          <li v-if="item.labels.count">
            <span
              :id="`${item.iid}-labels`"
              class="gl-display-flex gl-align-items-center"
              data-testid="labels"
            >
              <gl-icon name="label" class="gl-mr-1" />
              {{ item.labels.count }}
            </span>
            <gl-popover
              :target="`${item.iid}-labels`"
              placement="top"
              :css-classes="['issue-labels-popover']"
              data-testid="labelsPopover"
            >
              <div class="gl-display-flex gl-justify-content-start gl-flex-wrap gl-mr-1">
                <gl-label
                  v-for="label in item.labels.nodes"
                  :key="label.id"
                  :title="label.title"
                  :background-color="label.color"
                  :description="label.description"
                  :scoped="label.title.includes('::')"
                  class="gl-ml-1 gl-mt-1"
                  :target="labelTarget(label.title)"
                />
              </div>
            </gl-popover>
          </li>
        </ul>
      </div>
    </template>

    <template #cell(createdAt)="{ value }">
      <div data-testid="ageCol">{{ formatAge(value) }}</div>
    </template>

    <template #cell(state)="{ value }">
      <div data-testid="statusCol">{{ formatStatus(value) }}</div>
    </template>

    <template #cell(milestone)="{ value }">
      <template v-if="value">
        <div class="milestone-title str-truncated">
          {{ value.title }}
        </div>
      </template>
    </template>

    <template #cell(iteration)="{ value }">
      <div data-testid="iterationCol" class="iteration-title str-truncated">
        {{ value.title }}
      </div>
    </template>

    <template #cell(assignees)="{ value }">
      <gl-avatars-inline
        :avatars="value.nodes"
        :avatar-size="$options.avatarSize"
        :max-visible="$options.MAX_VISIBLE_ASSIGNEES"
        :badge-sr-only-text="assigneesBadgeSrOnlyText(value.nodes)"
        collapsed
      >
        <template #avatar="{ avatar }">
          <gl-avatar-link v-gl-tooltip target="_blank" :href="avatar.webUrl" :title="avatar.name">
            <gl-avatar :src="avatar.avatarUrl" :size="$options.avatarSize" />
          </gl-avatar-link>
        </template>
      </gl-avatars-inline>
    </template>

    <template #cell(author)="{ value }">
      <gl-avatar-link v-gl-tooltip target="_blank" :href="value.webUrl" :title="value.name">
        <gl-avatar :size="$options.avatarSize" :src="value.avatarUrl" :entity-name="value.name" />
      </gl-avatar-link>
    </template>
  </gl-table-lite>
</template>
