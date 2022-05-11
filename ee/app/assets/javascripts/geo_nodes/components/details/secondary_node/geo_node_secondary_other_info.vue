<script>
import { GlCard } from '@gitlab/ui';
import { parseSeconds, stringifyTime } from '~/lib/utils/datetime_utility';
import { __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'GeoNodeSecondaryOtherInfo',
  i18n: {
    otherInfo: __('Other information'),
    dbReplicationLag: s__('Geo|Data replication lag'),
    lastEventId: s__('Geo|Last event ID from primary'),
    lastCursorEventId: s__('Geo|Last event ID processed by cursor'),
    storageConfig: s__('Geo|Storage config'),
    shardsNotMatched: s__('Geo|Does not match the primary storage configuration'),
    unknown: __('Unknown'),
    ok: __('OK'),
  },
  classTimestamp: 'gl-text-gray-500 gl-font-sm gl-font-weight-normal',
  components: {
    GlCard,
    TimeAgo,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
  },
  computed: {
    storageShardsStatus() {
      if (this.node.storageShardsMatch == null) {
        return this.$options.i18n.unknown;
      }

      return this.node.storageShardsMatch
        ? this.$options.i18n.ok
        : this.$options.i18n.shardsNotMatched;
    },
    dbReplicationLag() {
      if (parseInt(this.node.dbReplicationLagSeconds, 10) >= 0) {
        const parsedTime = parseSeconds(this.node.dbReplicationLagSeconds, {
          hoursPerDay: 24,
          daysPerWeek: 7,
        });

        return stringifyTime(parsedTime);
      }

      return this.$options.i18n.unknown;
    },
    lastEventTimestamp() {
      // Converting timestamp to ms
      return this.node.lastEventTimestamp * 1000;
    },
    lastCursorEventTimestamp() {
      // Converting timestamp to ms
      return this.node.cursorLastEventTimestamp * 1000;
    },
    hasEventInfo() {
      return this.node.lastEventId || this.lastEventTimestamp;
    },
    hasCursorEventInfo() {
      return this.node.cursorLastEventId || this.lastCursorEventTimestamp;
    },
  },
};
</script>

<template>
  <gl-card>
    <template #header>
      <h5 class="gl-my-3">{{ $options.i18n.otherInfo }}</h5>
    </template>
    <div class="gl-display-flex gl-flex-direction-column gl-mb-5">
      <span>{{ $options.i18n.dbReplicationLag }}</span>
      <span class="gl-font-weight-bold gl-mt-2" data-testid="replication-lag">{{
        dbReplicationLag
      }}</span>
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-mb-5">
      <span>{{ $options.i18n.lastEventId }}</span>
      <div class="gl-font-weight-bold gl-mt-2" data-testid="last-event">
        <template v-if="hasEventInfo">
          <span v-if="node.lastEventId">{{ node.lastEventId }}</span>
          <span v-if="lastEventTimestamp" :class="$options.classTimestamp">
            <time-ago :time="lastEventTimestamp" />
          </span>
        </template>
        <span v-else>{{ $options.i18n.unknown }}</span>
      </div>
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-mb-5">
      <span>{{ $options.i18n.lastCursorEventId }}</span>
      <div class="gl-font-weight-bold gl-mt-2" data-testid="last-cursor-event">
        <template v-if="hasCursorEventInfo">
          <span v-if="node.cursorLastEventId">{{ node.cursorLastEventId }}</span>
          <span v-if="lastCursorEventTimestamp" :class="$options.classTimestamp">
            <time-ago :time="lastCursorEventTimestamp" />
          </span>
        </template>
        <span v-else>{{ $options.i18n.unknown }}</span>
      </div>
    </div>
    <div class="gl-display-flex gl-flex-direction-column gl-mb-5">
      <span>{{ $options.i18n.storageConfig }}</span>
      <span class="gl-font-weight-bold gl-mt-2" data-testid="storage-shards">{{
        storageShardsStatus
      }}</span>
    </div>
  </gl-card>
</template>
