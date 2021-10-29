<script>
import { GlTab, GlBadge, GlLink, GlTable, GlKeysetPagination } from '@gitlab/ui';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { DAST_SHORT_NAME } from '~/security_configuration/components/constants';
import { __ } from '~/locale';
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
  },
};
</script>

<template>
  <gl-tab v-bind="$attrs">
    <template #title>
      {{ title }}
      <gl-badge size="sm" class="gl-tab-counter-badge">{{ itemsCount }}</gl-badge>
    </template>
    <template v-if="hasPipelines">
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
    <empty-state v-else :title="emptyStateTitle" :text="emptyStateText" no-primary-button />
  </gl-tab>
</template>
