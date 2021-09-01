<script>
import { GlIcon, GlPopover, GlLink } from '@gitlab/ui';
import GeoNodeProgressBar from 'ee/geo_nodes/components/details/geo_node_progress_bar.vue';
import { HELP_INFO_URL } from 'ee/geo_nodes/constants';
import { s__, __ } from '~/locale';

export default {
  name: 'GeoNodeReplicationDetailsResponsive',
  i18n: {
    dataType: __('Data type'),
    component: __('Component'),
    status: __('Status'),
    syncStatus: s__('Geo|Synchronization status'),
    verifStatus: s__('Geo|Verification status'),
    popoverHelpText: s__(
      'Geo|Replicated data is verified with the secondary site(s) using checksums',
    ),
    learnMore: __('Learn more'),
    nA: __('N/A'),
    progressBarSyncTitle: s__('Geo|%{component} synced'),
    progressBarVerifTitle: s__('Geo|%{component} verified'),
    verified: s__('Geo|Verified'),
    nothingToVerify: s__('Geo|Nothing to verify'),
  },
  components: {
    GlIcon,
    GlPopover,
    GlLink,
    GeoNodeProgressBar,
  },
  props: {
    replicationItems: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  HELP_INFO_URL,
};
</script>

<template>
  <div>
    <div
      class="gl-display-grid geo-node-replication-details-grid-columns gl-bg-gray-10 gl-p-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
      data-testid="replication-details-header"
    >
      <slot name="title" :translations="$options.i18n">
        <span class="gl-font-weight-bold">{{ $options.i18n.dataType }}</span>
        <span class="gl-font-weight-bold">{{ $options.i18n.component }}</span>
        <span class="gl-font-weight-bold">{{ $options.i18n.syncStatus }}</span>
        <div class="gl-display-flex gl-align-items-center">
          <span class="gl-font-weight-bold">{{ $options.i18n.verifStatus }}</span>
          <gl-icon
            ref="verificationStatus"
            tabindex="0"
            name="question"
            class="gl-text-blue-500 gl-cursor-pointer gl-ml-2"
          />
          <gl-popover
            :target="() => $refs.verificationStatus.$el"
            placement="top"
            triggers="hover focus"
          >
            <p class="gl-font-base">
              {{ $options.i18n.popoverHelpText }}
            </p>
            <gl-link :href="$options.HELP_INFO_URL" target="_blank">{{
              $options.i18n.learnMore
            }}</gl-link>
          </gl-popover>
        </div>
      </slot>
    </div>
    <div
      v-for="item in replicationItems"
      :key="item.component"
      class="gl-display-grid geo-node-replication-details-grid-columns gl-p-5 gl-border-b-1 gl-border-b-solid gl-border-b-gray-100"
      data-testid="replication-details-item"
    >
      <slot :item="item" :translations="$options.i18n">
        <span class="gl-mr-5">{{ item.dataTypeTitle }}</span>
        <span class="gl-mr-5">{{ item.component }}</span>
        <div class="gl-mr-5" data-testid="sync-status">
          <geo-node-progress-bar
            v-if="item.syncValues"
            :title="sprintf($options.i18n.progressBarSyncTitle, { component: item.component })"
            :target="`sync-progress-${item.component}`"
            :values="item.syncValues"
          />
          <span v-else class="gl-text-gray-400 gl-font-sm">{{ $options.i18n.nA }}</span>
        </div>
        <div data-testid="verification-status">
          <geo-node-progress-bar
            v-if="item.verificationValues"
            :title="sprintf($options.i18n.progressBarVerifTitle, { component: item.component })"
            :target="`verification-progress-${item.component}`"
            :values="item.verificationValues"
            :success-label="$options.i18n.verified"
            :unavailable-label="$options.i18n.nothingToVerify"
          />
          <span v-else class="gl-text-gray-400 gl-font-sm">{{ $options.i18n.nA }}</span>
        </div>
      </slot>
    </div>
  </div>
</template>
