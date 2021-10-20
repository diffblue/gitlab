<script>
import {
  GlTab,
  GlBadge,
  GlLink,
  GlTable,
  GlKeysetPagination,
  GlAlert,
  GlSkeletonLoader,
} from '@gitlab/ui';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { DAST_SHORT_NAME } from '~/security_configuration/components/constants';
import { __, s__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { scrollToElement } from '~/lib/utils/common_utils';
import EmptyState from '../empty_state.vue';
import { PIPELINES_PER_PAGE, PIPELINES_POLL_INTERVAL } from '../../constants';

const defaultCursor = {
  first: PIPELINES_PER_PAGE,
  last: null,
  after: null,
  before: null,
};

export default {
  PIPELINES_PER_PAGE,
  DAST_SHORT_NAME,
  getIdFromGraphQLId,
  components: {
    GlTab,
    GlBadge,
    GlLink,
    GlTable,
    GlKeysetPagination,
    GlAlert,
    GlSkeletonLoader,
    CiBadgeLink,
    TimeAgoTooltip,
    EmptyState,
  },
  inject: ['projectPath'],
  props: {
    query: {
      type: Object,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    itemsCount: {
      type: Number,
      required: true,
    },
    emptyStateTitle: {
      type: String,
      required: false,
      default: undefined,
    },
    emptyStateText: {
      type: String,
      required: false,
      default: undefined,
    },
    fields: {
      type: Array,
      required: true,
    },
  },
  apollo: {
    pipelines: {
      query() {
        return this.query;
      },
      variables() {
        return {
          fullPath: this.projectPath,
          ...this.cursor,
        };
      },
      update(data) {
        const pipelines = data?.project?.pipelines;
        if (!pipelines?.nodes?.length && (this.cursor.after || this.cursor.before)) {
          this.resetCursor();
          this.updateRoute();
        }
        return pipelines;
      },
      error() {
        this.hasError = true;
      },
      pollInterval: PIPELINES_POLL_INTERVAL,
    },
  },
  data() {
    const { after, before } = this.$route.query;
    const cursor = { ...defaultCursor };

    if (after) {
      cursor.after = after;
    } else if (before) {
      cursor.before = before;
      cursor.first = null;
      cursor.last = PIPELINES_PER_PAGE;
    }

    return {
      cursor,
      hasError: false,
    };
  },
  computed: {
    hasPipelines() {
      return Boolean(this.pipelines?.nodes?.length);
    },
    tableFields() {
      return this.fields.map(({ key, label }) => ({
        key,
        label,
        class: ['gl-text-black-normal'],
        thClass: ['gl-bg-transparent!', 'gl-white-space-nowrap'],
      }));
    },
  },
  methods: {
    resetCursor() {
      this.cursor = { ...defaultCursor };
    },
    nextPage(after) {
      this.cursor = {
        ...defaultCursor,
        after,
      };
      this.updateRoute({ after });
    },
    prevPage(before) {
      this.cursor = {
        first: null,
        last: PIPELINES_PER_PAGE,
        after: null,
        before,
      };
      this.updateRoute({ before });
    },
    updateRoute(query = {}) {
      scrollToElement(this.$el);
      this.$router.push({
        path: this.$route.path,
        query,
      });
    },
  },
  i18n: {
    previousPage: __('Prev'),
    nextPage: __('Next'),
    errorMessage: s__(
      'OnDemandScans|Could not fetch on-demand scans. Please refresh the page, or try again later.',
    ),
  },
};
</script>

<template>
  <gl-tab v-bind="$attrs">
    <template #title>
      {{ title }}
      <gl-badge size="sm" class="gl-tab-counter-badge">{{ itemsCount }}</gl-badge>
    </template>
    <template v-if="$apollo.queries.pipelines.loading">
      <gl-skeleton-loader v-for="i in 20" :key="i" :width="815" :height="50">
        <rect width="85" height="20" x="15" y="15" rx="4" />
        <rect width="155" height="20" x="125" y="15" rx="4" />
        <rect width="60" height="20" x="350" y="15" rx="4" />
        <rect width="150" height="20" x="450" y="15" rx="4" />
        <rect width="70" height="20" x="640" y="15" rx="4" />
        <rect width="25" height="20" x="740" y="15" rx="4" />
      </gl-skeleton-loader>
    </template>
    <template v-else-if="hasPipelines">
      <gl-table
        thead-class="gl-border-b-solid gl-border-gray-100 gl-border-1"
        :fields="tableFields"
        :items="pipelines.nodes"
        stacked="md"
      >
        <template #cell(detailedStatus)="{ item }">
          <div class="gl-my-3">
            <ci-badge-link :status="item.detailedStatus" />
          </div>
        </template>

        <template #cell(scanType)>
          {{ $options.DAST_SHORT_NAME }}
        </template>

        <template #cell(createdAt)="{ item }">
          <time-ago-tooltip v-if="item.createdAt" :time="item.createdAt" tooltip-placement="left" />
        </template>

        <template #cell(id)="{ item }">
          <gl-link :href="item.path">#{{ $options.getIdFromGraphQLId(item.id) }}</gl-link>
        </template>
      </gl-table>

      <div class="gl-display-flex gl-justify-content-center">
        <gl-keyset-pagination
          data-testid="pagination"
          v-bind="pipelines.pageInfo"
          :prev-text="$options.i18n.previousPage"
          :next-text="$options.i18n.nextPage"
          @prev="prevPage"
          @next="nextPage"
        />
      </div>
    </template>
    <template v-else-if="hasError">
      <gl-alert variant="danger" :dismissible="false" class="gl-my-4" data-testid="error-alert">
        {{ $options.i18n.errorMessage }}
      </gl-alert>
    </template>
    <empty-state v-else :title="emptyStateTitle" :text="emptyStateText" no-primary-button />
  </gl-tab>
</template>
