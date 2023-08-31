<script>
import { GlIcon, GlTooltip, GlTooltipDirective } from '@gitlab/ui';
import IssueHealthStatus from 'ee/related_items_tree/components/issue_health_status.vue';
import WorkItemLinkChildMetadata from '~/work_items/components/shared/work_item_link_child_metadata.vue';
import { WIDGET_TYPE_HEALTH_STATUS, WIDGET_TYPE_PROGRESS } from '~/work_items/constants';
import { formatDate } from '~/lib/utils/datetime_utility';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  name: 'WorkItemLinkChildEE',
  components: {
    GlIcon,
    GlTooltip,
    IssueHealthStatus,
    WorkItemLinkChildMetadata,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    metadataWidgets: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    progress() {
      return this.metadataWidgets[WIDGET_TYPE_PROGRESS]?.progress;
    },
    progressLastUpdatedAtInWords() {
      return this.getTimestampInWords(this.metadataWidgets[WIDGET_TYPE_PROGRESS]?.updatedAt);
    },
    progressLastUpdatedAtTimestamp() {
      return this.getTimestamp(this.metadataWidgets[WIDGET_TYPE_PROGRESS]?.updatedAt);
    },
    healthStatus() {
      return this.metadataWidgets[WIDGET_TYPE_HEALTH_STATUS]?.healthStatus;
    },
    hasProgress() {
      return Number.isInteger(this.progress);
    },
  },
  methods: {
    getTimestamp(rawTimestamp) {
      return rawTimestamp ? formatDate(new Date(rawTimestamp)) : '';
    },
    getTimestampInWords(rawTimestamp) {
      return rawTimestamp ? this.timeFormatted(rawTimestamp) : '';
    },
  },
};
</script>

<template>
  <work-item-link-child-metadata :metadata-widgets="metadataWidgets">
    <issue-health-status v-if="healthStatus" :health-status="healthStatus" />
    <div
      v-if="hasProgress"
      ref="progressTooltip"
      class="gl-display-flex gl-align-items-center gl-mr-3 gl-cursor-help gl-line-height-normal"
      data-testid="item-progress"
    >
      <gl-icon name="progress" />
      <span data-testid="progressValue" class="gl-font-sm gl-text-primary gl-ml-2"
        >{{ progress }}%</span
      >
      <gl-tooltip :target="() => $refs.progressTooltip">
        <div data-testid="progressTitle" class="gl-font-weight-bold">
          {{ __('Progress') }}
        </div>
        <div v-if="progressLastUpdatedAtInWords" class="text-tertiary">
          <span data-testid="progressText" class="gl-font-weight-bold">
            {{ __('Last updated') }}
          </span>
          <span data-testid="lastUpdatedInWords">{{ progressLastUpdatedAtInWords }}</span>
          <div data-testid="lastUpdatedTimestamp">{{ progressLastUpdatedAtTimestamp }}</div>
        </div>
      </gl-tooltip>
    </div>
  </work-item-link-child-metadata>
</template>
