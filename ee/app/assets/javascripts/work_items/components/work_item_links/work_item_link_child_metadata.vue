<script>
import { GlIcon, GlBadge, GlTooltipDirective } from '@gitlab/ui';

import WorkItemLinkChildMetadata from '~/work_items/components/work_item_links/work_item_link_child_metadata.vue';
import { WIDGET_TYPE_PROGRESS, WIDGET_TYPE_HEALTH_STATUS } from '~/work_items/constants';

import { healthStatusTextMap } from 'ee/sidebar/constants';
import { issueHealthStatusVariantMapping } from 'ee/related_items_tree/constants';

export default {
  name: 'WorkItemLinkChildEE',
  components: {
    GlIcon,
    GlBadge,
    WorkItemLinkChildMetadata,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
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
    healthStatus() {
      return this.metadataWidgets[WIDGET_TYPE_HEALTH_STATUS]?.healthStatus;
    },
    hasProgress() {
      return Number.isInteger(this.progress);
    },
    hasHealthStatus() {
      return this.healthStatus !== null;
    },
    healthStatusText() {
      return this.hasHealthStatus ? healthStatusTextMap[this.healthStatus] : '';
    },
    healthStatusVariant() {
      return this.hasHealthStatus ? issueHealthStatusVariantMapping[this.healthStatus] : '';
    },
  },
};
</script>

<template>
  <work-item-link-child-metadata :metadata-widgets="metadataWidgets">
    <div
      v-if="hasProgress"
      v-gl-tooltip.bottom
      :title="__('Progress')"
      class="gl-display-flex gl-align-items-center gl-mr-5 gl-cursor-help gl-line-height-normal"
      data-testid="item-progress"
    >
      <gl-icon name="progress" />
      <span class="gl-text-primary gl-ml-2">{{ progress }}%</span>
    </div>
    <gl-badge
      v-if="hasHealthStatus"
      v-gl-tooltip.bottom
      :variant="healthStatusVariant"
      :title="s__('WorkItem|Health status')"
      size="sm"
      class="gl-mr-5 gl-cursor-help"
      >{{ healthStatusText }}</gl-badge
    >
  </work-item-link-child-metadata>
</template>
