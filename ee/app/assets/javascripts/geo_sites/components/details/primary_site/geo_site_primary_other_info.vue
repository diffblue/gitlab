<script>
import { GlCard } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { secondsToMilliseconds } from '~/lib/utils/datetime_utility';
import { __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import GeoSiteProgressBar from '../geo_site_progress_bar.vue';

export default {
  name: 'GeoSitePrimaryOtherInfo',
  i18n: {
    otherInformation: __('Other information'),
    replicationSlotWAL: s__('Geo|Replication slot WAL'),
    replicationSlots: s__('Geo|Replication slots'),
    unknown: __('Unknown'),
    used: __('Used'),
    unused: __('Unused'),
    noAvailableSlots: s__('Geo|No available replication slots'),
    lastEventId: s__('Geo|Last event ID'),
  },
  components: {
    GlCard,
    GeoSiteProgressBar,
    TimeAgo,
  },
  props: {
    site: {
      type: Object,
      required: true,
    },
  },
  computed: {
    replicationSlotWAL() {
      return this.site.replicationSlotsMaxRetainedWalBytes ||
        this.site.replicationSlotsMaxRetainedWalBytes === 0
        ? numberToHumanSize(this.site.replicationSlotsMaxRetainedWalBytes)
        : this.$options.i18n.unknown;
    },
    replicationSlots() {
      return {
        title: this.$options.i18n.replicationSlots,
        values: {
          total: this.site.replicationSlotsCount || 0,
          success: this.site.replicationSlotsUsedCount || 0,
        },
      };
    },
    hasEventInfo() {
      return this.site.lastEventId || this.lastEventTimestampInMillis;
    },
    lastEventTimestampInMillis() {
      // Converting timestamp to ms
      return secondsToMilliseconds(this.site.lastEventTimestamp);
    },
  },
};
</script>

<template>
  <gl-card>
    <template #header>
      <h5 class="gl-my-0">{{ $options.i18n.otherInformation }}</h5>
    </template>
    <div class="gl-mb-5">
      <span>{{ replicationSlots.title }}</span>
      <geo-site-progress-bar
        class="gl-mt-3"
        :title="replicationSlots.title"
        :values="replicationSlots.values"
        :success-label="$options.i18n.used"
        :queued-label="$options.i18n.unused"
        :unavailable-label="$options.i18n.noAvailableSlots"
      />
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-mb-5">
      <span>{{ $options.i18n.replicationSlotWAL }}</span>
      <span class="gl-font-weight-bold gl-mt-2" data-testid="replication-slot-wal">{{
        replicationSlotWAL
      }}</span>
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-mb-5">
      <span>{{ $options.i18n.lastEventId }}</span>
      <div class="gl-font-weight-bold gl-mt-2" data-testid="last-event">
        <template v-if="hasEventInfo">
          <span>{{ site.lastEventId }}</span>
          <time-ago
            v-if="lastEventTimestampInMillis"
            :time="lastEventTimestampInMillis"
            class="gl-text-gray-500 gl-font-sm gl-font-weight-normal"
          />
        </template>
        <span v-else>{{ $options.i18n.unknown }}</span>
      </div>
    </div>
  </gl-card>
</template>
