<script>
import { GlIcon, GlBadge, GlTooltip, GlTooltipDirective } from '@gitlab/ui';
import WorkItemLinkChildMetadata from '~/work_items/components/work_item_links/work_item_link_child_metadata.vue';
import { WIDGET_TYPE_PROGRESS, WIDGET_TYPE_HEALTH_STATUS } from '~/work_items/constants';
import { healthStatusTextMap } from 'ee/sidebar/constants';
import { issueHealthStatusVariantMapping } from 'ee/related_items_tree/constants';
import { formatDate } from '~/lib/utils/datetime_utility';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  name: 'WorkItemLinkChildEE',
  components: {
    GlIcon,
    GlBadge,
    GlTooltip,
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
    hasHealthStatus() {
      return Boolean(this.healthStatus);
    },
    healthStatusText() {
      return this.hasHealthStatus ? healthStatusTextMap[this.healthStatus] : '';
    },
    healthStatusVariant() {
      return this.hasHealthStatus ? issueHealthStatusVariantMapping[this.healthStatus] : '';
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
    <gl-badge
      v-if="hasHealthStatus"
      v-gl-tooltip.bottom
      :variant="healthStatusVariant"
      :title="s__('WorkItem|Health status')"
      size="sm"
      class="gl-cursor-help gl-align-self-center"
      >{{ healthStatusText }}</gl-badge
    >
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
