<script>
import { timeIntervalInWords } from '~/lib/utils/datetime_utility';
import { sprintf, __, s__ } from '~/locale';

export default {
  name: 'GeoSiteSyncSettings',
  i18n: {
    full: __('Full'),
    groups: __('groups'),
    syncLabel: s__('Geo|Selective (%{syncLabel})'),
    pendingEvents: s__('Geo|%{timeAgoStr} (%{pendingEvents} events)'),
  },
  props: {
    site: {
      type: Object,
      required: true,
    },
  },

  computed: {
    syncType() {
      if (this.site.selectiveSyncType === null || this.site.selectiveSyncType === '') {
        return this.$options.i18n.full;
      }

      // Renaming namespaces to groups in the UI for Geo Selective Sync
      const syncLabel =
        this.site.selectiveSyncType === 'namespaces'
          ? this.$options.i18n.groups
          : this.site.selectiveSyncType;

      return sprintf(this.$options.i18n.syncLabel, { syncLabel });
    },
    eventTimestampEmpty() {
      return !this.site.lastEventTimestamp || !this.site.cursorLastEventTimestamp;
    },
    syncLagInSeconds() {
      return this.site.cursorLastEventTimestamp - this.site.lastEventTimestamp;
    },
    syncStatusEventInfo() {
      const timeAgoStr = timeIntervalInWords(this.syncLagInSeconds);
      const pendingEvents = this.site.lastEventId - this.site.cursorLastEventId;

      return sprintf(this.$options.i18n.pendingEvents, {
        timeAgoStr,
        pendingEvents,
      });
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <span class="gl-font-weight-bold" data-testid="sync-type">{{ syncType }}</span>
    <span
      v-if="!eventTimestampEmpty"
      class="gl-ml-3 gl-text-gray-500 gl-font-sm"
      data-testid="sync-status-event-info"
    >
      {{ syncStatusEventInfo }}
    </span>
  </div>
</template>
