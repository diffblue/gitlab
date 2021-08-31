<script>
/* eslint-disable vue/no-v-html */
import {
  GlAlert,
  GlDropdown,
  GlDropdownItem,
  GlEmptyState,
  GlIcon,
  GlLoadingIcon,
} from '@gitlab/ui';
import BurnCharts from 'ee/burndown_chart/components/burn_charts.vue';
import { TYPE_ITERATION } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { Namespace } from '../constants';
import query from '../queries/iteration.query.graphql';
import IterationReportTabs from './iteration_report_tabs.vue';
import TimeboxStatusBadge from './timebox_status_badge.vue';

export default {
  components: {
    BurnCharts,
    GlAlert,
    GlIcon,
    GlDropdown,
    GlDropdownItem,
    GlEmptyState,
    GlLoadingIcon,
    IterationReportTabs,
    TimeboxStatusBadge,
  },
  apollo: {
    iteration: {
      query,
      variables() {
        return {
          fullPath: this.fullPath,
          id: convertToGraphQLId(TYPE_ITERATION, this.iterationId),
          isGroup: this.namespaceType === Namespace.Group,
        };
      },
      update(data) {
        return data[this.namespaceType]?.iterations?.nodes[0] || {};
      },
      error(err) {
        this.error = s__('Iterations|Unable to find iteration.');
        // eslint-disable-next-line no-console
        console.error(err.message);
      },
    },
  },
  mixins: [glFeatureFlagsMixin()],
  inject: [
    'fullPath',
    'hasScopedLabelsFeature',
    'canEditIteration',
    'namespaceType',
    'noIssuesSvgPath',
    'labelsFetchPath',
  ],
  data() {
    return {
      error: '',
      iteration: {},
    };
  },
  computed: {
    canEdit() {
      return this.canEditIteration && this.namespaceType === Namespace.Group;
    },
    loading() {
      return this.$apollo.queries.iteration.loading;
    },
    iterationId() {
      return this.$router.currentRoute.params.iterationId;
    },
    showEmptyState() {
      return !this.loading && this.iteration && !this.iteration.title;
    },
    editPage() {
      return {
        name: 'editIteration',
      };
    },
  },
  methods: {
    formatDate(date) {
      return formatDate(date, 'mmm d, yyyy', true);
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" @dismiss="error = ''">
      {{ error }}
    </gl-alert>
    <gl-loading-icon v-else-if="loading" class="gl-py-5" size="lg" />
    <gl-empty-state
      v-else-if="showEmptyState"
      :title="__('Could not find iteration')"
      :compact="false"
    />
    <template v-else>
      <div
        ref="topbar"
        class="gl-display-flex gl-justify-items-center gl-align-items-center gl-py-3 gl-border-1 gl-border-b-solid gl-border-gray-100"
      >
        <timebox-status-badge :state="iteration.state" />
        <span class="gl-ml-4"
          >{{ formatDate(iteration.startDate) }} – {{ formatDate(iteration.dueDate) }}</span
        >
        <gl-dropdown
          v-if="canEdit"
          data-testid="actions-dropdown"
          variant="default"
          toggle-class="gl-text-decoration-none gl-border-0! gl-shadow-none!"
          class="gl-ml-auto gl-text-secondary"
          right
          no-caret
        >
          <template #button-content>
            <gl-icon name="ellipsis_v" /><span class="gl-sr-only">{{ __('Actions') }}</span>
          </template>
          <gl-dropdown-item :to="editPage">{{ __('Edit') }}</gl-dropdown-item>
        </gl-dropdown>
      </div>
      <h3 ref="title" class="page-title">{{ iteration.title }}</h3>
      <div ref="description" v-html="iteration.descriptionHtml"></div>
      <burn-charts
        :start-date="iteration.startDate"
        :due-date="iteration.dueDate"
        :iteration-id="iteration.id"
        :iteration-state="iteration.state"
        :full-path="fullPath"
        :namespace-type="namespaceType"
      />
      <iteration-report-tabs
        :full-path="fullPath"
        :has-scoped-labels-feature="hasScopedLabelsFeature"
        :iteration-id="iteration.id"
        :labels-fetch-path="labelsFetchPath"
        :namespace-type="namespaceType"
        :svg-path="noIssuesSvgPath"
      />
    </template>
  </div>
</template>
