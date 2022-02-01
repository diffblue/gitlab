<script>
import {
  GlAlert,
  GlAvatar,
  GlAvatarLink,
  GlAvatarsInline,
  GlIntersectionObserver,
  GlLoadingIcon,
  GlTable,
  GlLink,
  GlSkeletonLoading,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import produce from 'immer';
import { n__ } from '~/locale';
import getAlertsQuery from '~/graphql_shared/queries/get_alerts.query.graphql';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { joinPaths } from '~/lib/utils/url_utility';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { PAGE_SIZE } from 'ee/threat_monitoring/constants';
import AlertDrawer from './alert_drawer.vue';
import AlertFilters from './alert_filters.vue';
import AlertStatus from './alert_status.vue';
import { DEFAULT_FILTERS, FIELDS, MESSAGES, STATUSES, DOMAIN, CLOSED } from './constants';

const MAX_VISIBLE_ASSIGNEES = 4;

export default {
  PAGE_SIZE,
  DOMAIN,
  i18n: {
    FIELDS,
    MESSAGES,
    STATUSES,
    CLOSED,
  },
  MAX_VISIBLE_ASSIGNEES,
  components: {
    AlertDrawer,
    AlertStatus,
    AlertFilters,
    GlAlert,
    GlAvatar,
    GlAvatarLink,
    GlAvatarsInline,
    GlIntersectionObserver,
    GlLink,
    GlLoadingIcon,
    GlSkeletonLoading,
    GlSprintf,
    GlTable,
    TimeAgo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  provide: {
    statuses: STATUSES,
  },
  inject: ['documentationPath', 'projectPath'],
  apollo: {
    alerts: {
      query: getAlertsQuery,
      variables() {
        return {
          firstPageSize: this.$options.PAGE_SIZE,
          projectPath: this.projectPath,
          sort: this.sort,
          domain: this.$options.DOMAIN,
          ...this.filters,
        };
      },
      update: ({ project }) => project?.alertManagementAlerts.nodes || [],
      result({ data }) {
        this.pageInfo = data?.project?.alertManagementAlerts?.pageInfo || {};
        if (this.selectedAlert) {
          this.selectedAlert = data?.project?.alertManagementAlerts?.nodes?.find(
            (alert) => alert.iid === this.selectedAlert.iid,
          );
        }
      },
      error() {
        this.errored = true;
      },
    },
  },
  data() {
    return {
      alerts: [],
      errored: false,
      errorMsg: '',
      filters: DEFAULT_FILTERS,
      isAlertDrawerOpen: false,
      isErrorAlertDismissed: false,
      pageInfo: {},
      selectedAlert: null,
      sort: 'STARTED_AT_DESC',
      sortBy: 'startedAt',
      sortDesc: true,
      sortDirection: 'desc',
    };
  },
  computed: {
    isEmpty() {
      return !this.alerts.length;
    },
    isLoadingAlerts() {
      return this.$apollo.queries.alerts.loading;
    },
    isLoadingFirstAlerts() {
      return this.isLoadingAlerts && this.isEmpty;
    },
    showNoAlertsMsg() {
      return this.isEmpty && !this.isLoadingAlerts && !this.errored && !this.isErrorAlertDismissed;
    },
  },
  methods: {
    errorAlertDismissed() {
      this.errored = false;
      this.errorMsg = '';
      this.isErrorAlertDismissed = true;
    },
    fetchNextPage() {
      if (this.pageInfo.hasNextPage) {
        this.$apollo.queries.alerts.fetchMore({
          variables: { nextPageCursor: this.pageInfo.endCursor },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            const results = produce(fetchMoreResult, (draftData) => {
              draftData.project.alertManagementAlerts.nodes = [
                ...previousResult.project.alertManagementAlerts.nodes,
                ...draftData.project.alertManagementAlerts.nodes,
              ];
            });
            return results;
          },
        });
      }
    },
    fetchSortedData({ sortBy, sortDesc }) {
      const sortingDirection = sortDesc ? 'DESC' : 'ASC';
      const sortingColumn = convertToSnakeCase(sortBy).toUpperCase();

      this.sort = `${sortingColumn}_${sortingDirection}`;
    },
    getIssueState({ issue: { state } }) {
      return state === 'closed' ? `(${this.$options.i18n.CLOSED})` : '';
    },
    handleAlertDeselect() {
      this.isAlertDrawerOpen = false;
      this.selectedAlert = null;
    },
    handleAlertError(msg) {
      this.errored = true;
      this.errorMsg = msg;
    },
    handleFilterChange(newFilters) {
      this.filters = newFilters;
    },
    handleAlertUpdate() {
      this.$apollo.queries.alerts.refetch();
    },
    hasAssignees(assignees) {
      return Boolean(assignees.nodes?.length);
    },
    alertDetailsUrl({ iid }) {
      return joinPaths(window.location.pathname, 'alerts', iid);
    },
    openAlertDrawer(data) {
      this.isAlertDrawerOpen = true;
      this.selectedAlert = data;
    },
    assigneesBadgeSrOnlyText(assignees) {
      return n__(
        '%d additional assignee',
        '%d additional assignees',
        assignees.length - MAX_VISIBLE_ASSIGNEES,
      );
    },
  },
};
</script>
<template>
  <div>
    <alert-filters :filters="filters" @filter-change="handleFilterChange" />
    <gl-alert v-if="showNoAlertsMsg" data-testid="threat-alerts-unconfigured" :dismissible="false">
      <gl-sprintf :message="$options.i18n.MESSAGES.CONFIGURE">
        <template #link="{ content }">
          <gl-link class="gl-display-inline-block" :href="documentationPath" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <gl-alert
      v-if="errored"
      variant="danger"
      data-testid="threat-alerts-error"
      @dismiss="errorAlertDismissed"
    >
      {{ errorMsg || $options.i18n.MESSAGES.ERROR }}
    </gl-alert>

    <gl-table
      class="alert-management-table"
      data-qa-selector="alerts_list"
      :busy="isLoadingFirstAlerts"
      :items="alerts"
      :fields="$options.i18n.FIELDS"
      stacked="md"
      :no-local-sorting="true"
      :sort-direction="sortDirection"
      :sort-desc.sync="sortDesc"
      :sort-by.sync="sortBy"
      thead-class="gl-border-b-solid gl-border-b-1 gl-border-b-gray-100"
      sort-icon-left
      responsive
      show-empty
      @row-clicked="openAlertDrawer"
      @sort-changed="fetchSortedData"
    >
      <template #cell(startedAt)="{ item }">
        <time-ago
          v-if="item.startedAt"
          :time="item.startedAt"
          data-testid="threat-alerts-started-at"
        />
      </template>

      <template #cell(alertLabel)="{ item }">
        <gl-link
          class="gl-word-break-all gl-text-body!"
          :title="`${item.iid} - ${item.title}`"
          :href="alertDetailsUrl(item)"
          data-testid="threat-alerts-id"
        >
          {{ item.title }}
        </gl-link>
      </template>

      <template #cell(eventCount)="{ item }">
        <div data-testid="threat-alerts-event-count">
          {{ item.eventCount }}
        </div>
      </template>

      <template #cell(issue)="{ item }">
        <div data-testid="threat-alerts-issue">
          <gl-link
            v-if="item.issue"
            v-gl-tooltip
            :title="item.issue.title"
            :href="item.issue.webUrl"
          >
            #{{ item.issue.iid }} {{ getIssueState(item) }}
          </gl-link>
          <span v-else>-</span>
        </div>
      </template>

      <template #cell(assignees)="{ item }">
        <div class="gl-display-flex" data-testid="threat-alerts-assignee">
          <gl-avatars-inline
            v-if="hasAssignees(item.assignees)"
            data-testid="assigneesField"
            :avatars="item.assignees.nodes"
            :collapsed="true"
            :max-visible="$options.MAX_VISIBLE_ASSIGNEES"
            :avatar-size="24"
            badge-tooltip-prop="name"
            :badge-tooltip-max-chars="100"
            :badge-sr-only-text="assigneesBadgeSrOnlyText(item.assignees.nodes)"
          >
            <template #avatar="{ avatar }">
              <gl-avatar-link
                :key="avatar.username"
                v-gl-tooltip
                target="_blank"
                :href="avatar.webUrl"
                :title="avatar.name"
              >
                <gl-avatar :src="avatar.avatarUrl" :label="avatar.name" :size="24" />
              </gl-avatar-link>
            </template>
          </gl-avatars-inline>
          <span v-else class="gl-ml-3">-</span>
        </div>
      </template>

      <template #cell(status)="{ item }">
        <alert-status
          :alert="item"
          :project-path="projectPath"
          @alert-error="handleAlertError"
          @alert-update="handleAlertUpdate"
        />
      </template>

      <template #table-busy>
        <gl-skeleton-loading
          v-for="n in $options.PAGE_SIZE"
          :key="n"
          class="gl-m-3 js-skeleton-loader"
          :lines="1"
          data-testid="threat-alerts-busy-state"
        />
      </template>

      <template #empty>
        <div data-testid="threat-alerts-empty-state">
          {{ $options.i18n.MESSAGES.NO_ALERTS }}
        </div>
      </template>
    </gl-table>

    <gl-intersection-observer
      v-if="pageInfo.hasNextPage"
      class="text-center"
      @appear="fetchNextPage"
    >
      <gl-loading-icon v-if="isLoadingAlerts" size="md" />
      <span v-else>&nbsp;</span>
    </gl-intersection-observer>
    <alert-drawer
      v-if="selectedAlert"
      :is-alert-drawer-open="isAlertDrawerOpen"
      :selected-alert="selectedAlert"
      @deselect-alert="handleAlertDeselect"
      @alert-update="handleAlertUpdate"
    />
  </div>
</template>
