<script>
import { GlPopover } from '@gitlab/ui';
import { toNumber } from 'lodash';
import { __, s__ } from '~/locale';
import StackedProgressBar from '~/vue_shared/components/stacked_progress_bar.vue';

export default {
  name: 'GeoSiteSyncProgress',
  i18n: {
    total: __('Total'),
  },
  components: {
    GlPopover,
    StackedProgressBar,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    values: {
      type: Object,
      required: true,
    },
    target: {
      type: String,
      required: false,
      default: null,
    },
    successLabel: {
      type: String,
      required: false,
      default: s__('Geo|Synced'),
    },
    queuedLabel: {
      type: String,
      required: false,
      default: s__('Geo|Queued'),
    },
    failedLabel: {
      type: String,
      required: false,
      default: __('Failed'),
    },
    unavailableLabel: {
      type: String,
      required: false,
      default: s__('Geo|Nothing to synchronize'),
    },
  },
  computed: {
    queuedCount() {
      return this.totalCount - this.successCount - this.failureCount;
    },
    totalCount() {
      return toNumber(this.values.total) || 0;
    },
    failureCount() {
      return toNumber(this.values.failed) || 0;
    },
    successCount() {
      return toNumber(this.values.success) || 0;
    },
    popoverTarget() {
      return this.target ? this.target : `syncProgress-${this.title}`;
    },
  },
};
</script>

<template>
  <div>
    <stacked-progress-bar
      :id="popoverTarget"
      tabindex="0"
      hide-tooltips
      :unavailable-label="unavailableLabel"
      :success-count="successCount"
      :failure-count="failureCount"
      :total-count="totalCount"
    />
    <gl-popover
      :target="popoverTarget"
      placement="right"
      triggers="hover focus"
      :css-classes="['w-100']"
      :title="title"
    >
      <section>
        <div class="gl-display-flex gl-align-items-center gl-my-3" data-testid="geo-progress-count">
          <div class="gl-mr-3 gl-bg-transparent gl-w-5 gl-h-2"></div>
          <span class="gl-flex-grow-1 gl-mr-4">{{ $options.i18n.total }}</span>
          <span class="gl-font-weight-bold">{{ totalCount.toLocaleString() }}</span>
        </div>
        <div class="gl-display-flex gl-align-items-center gl-my-3" data-testid="geo-progress-count">
          <div class="gl-mr-3 gl-bg-green-500 gl-w-5 gl-h-2"></div>
          <span class="gl-flex-grow-1 gl-mr-4">{{ successLabel }}</span>
          <span class="gl-font-weight-bold">{{ successCount.toLocaleString() }}</span>
        </div>
        <div class="gl-display-flex gl-align-items-center gl-my-3" data-testid="geo-progress-count">
          <div class="gl-mr-3 gl-bg-gray-200 gl-w-5 gl-h-2"></div>
          <span class="gl-flex-grow-1 gl-mr-4">{{ queuedLabel }}</span>
          <span class="gl-font-weight-bold">{{ queuedCount.toLocaleString() }}</span>
        </div>
        <div class="gl-display-flex gl-align-items-center gl-my-3" data-testid="geo-progress-count">
          <div class="gl-mr-3 gl-bg-red-500 gl-w-5 gl-h-2"></div>
          <span class="gl-flex-grow-1 gl-mr-4">{{ failedLabel }}</span>
          <span class="gl-font-weight-bold">{{ failureCount.toLocaleString() }}</span>
        </div>
      </section>
    </gl-popover>
  </div>
</template>
