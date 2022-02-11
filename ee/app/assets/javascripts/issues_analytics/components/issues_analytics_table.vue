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

import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { getDayDifference } from '~/lib/utils/datetime_utility';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { s__, n__ } from '~/locale';

const DEFAULT_API_URL_PARAMS = { with_labels_details: true, per_page: 100 };
const SYMBOL = {
  ISSUE: '#',
  EPIC: '&',
};
const MAX_VISIBLE_ASSIGNEES = 2;

const TH_TEST_ID = { 'data-testid': 'header' };

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
  props: {
    endpoints: {
      type: Object,
      required: true,
    },
  },
  tableHeaderFields: [
    {
      key: 'issue_details',
      label: s__('IssueAnalytics|Issue'),
      tdClass: 'issues-analytics-td',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'created_at',
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
      key: 'weight',
      label: s__('IssueAnalytics|Weight'),
      class: 'gl-text-right',
      thAttr: TH_TEST_ID,
    },
    {
      key: 'due_date',
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
      isLoading: true,
    };
  },
  computed: {
    shouldDisplayTable() {
      return this.issues.length;
    },
  },
  created() {
    this.fetchIssues();
  },
  methods: {
    fetchIssues() {
      return axios
        .get(mergeUrlParams(DEFAULT_API_URL_PARAMS, this.endpoints.api))
        .then(({ data }) => {
          this.issues = data;
          this.isLoading = false;
        })
        .catch(() => {
          createFlash({
            message: s__('IssueAnalytics|Failed to load issues. Please try again.'),
          });
          this.isLoading = false;
        });
    },
    formatAge(date) {
      return n__('%d day', '%d days', getDayDifference(new Date(date), new Date(Date.now())));
    },
    formatStatus(status) {
      return capitalizeFirstCharacter(status);
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
  <gl-loading-icon v-if="isLoading" size="md" />
  <gl-table-lite
    v-else-if="shouldDisplayTable"
    :fields="$options.tableHeaderFields"
    :items="issues"
    stacked="sm"
    thead-class="thead-white border-bottom"
    striped
  >
    <template #cell(issue_details)="{ item }">
      <div class="gl-display-flex gl-flex-direction-column gl-flex-grow-1" data-testid="detailsCol">
        <div class="issue-title str-truncated">
          <gl-link :href="item.web_url" target="_blank" class="gl-font-weight-bold text-plain">{{
            item.title
          }}</gl-link>
        </div>
        <ul class="horizontal-list list-items-separated gl-mb-0">
          <li>{{ formatIssueId(item.iid) }}</li>
          <li v-if="item.epic">{{ formatEpicId(item.epic.iid) }}</li>
          <li v-if="item.labels.length">
            <span :id="`${item.id}-labels`" class="gl-display-flex gl-align-items-center">
              <gl-icon name="label" class="gl-mr-1" />
              {{ item.labels.length }}
            </span>
            <gl-popover
              :target="`${item.id}-labels`"
              placement="top"
              :css-classes="['issue-labels-popover']"
            >
              <div class="gl-display-flex gl-justify-content-start gl-flex-wrap gl-mr-1">
                <gl-label
                  v-for="label in item.labels"
                  :key="label.id"
                  :title="label.name"
                  :background-color="label.color"
                  :description="label.description"
                  :scoped="label.name.includes('::')"
                  class="gl-ml-1 gl-mt-1"
                  :target="labelTarget(label.name)"
                />
              </div>
            </gl-popover>
          </li>
        </ul>
      </div>
    </template>

    <template #cell(created_at)="{ value }">
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

    <template #cell(assignees)="{ value }">
      <gl-avatars-inline
        :avatars="value"
        :avatar-size="$options.avatarSize"
        :max-visible="$options.MAX_VISIBLE_ASSIGNEES"
        :badge-sr-only-text="assigneesBadgeSrOnlyText(value)"
        collapsed
      >
        <template #avatar="{ avatar }">
          <gl-avatar-link v-gl-tooltip target="_blank" :href="avatar.web_url" :title="avatar.name">
            <gl-avatar :src="avatar.avatar_url" :size="$options.avatarSize" />
          </gl-avatar-link>
        </template>
      </gl-avatars-inline>
    </template>

    <template #cell(author)="{ value }">
      <gl-avatar-link v-gl-tooltip target="_blank" :href="value.web_url" :title="value.name">
        <gl-avatar :size="$options.avatarSize" :src="value.avatar_url" :entity-name="value.name" />
      </gl-avatar-link>
    </template>
  </gl-table-lite>
</template>
