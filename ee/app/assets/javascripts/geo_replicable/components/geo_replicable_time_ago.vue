<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'GeoReplicableTimeAgo',
  i18n: {
    timeAgoString: s__('Geo|%{label} %{timeAgo}'),
  },
  components: {
    TimeAgo,
    GlSprintf,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    defaultText: {
      type: String,
      required: true,
    },
    dateString: {
      type: String,
      required: false,
      default: '',
    },
    showDivider: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="gl-text-gray-700 gl-font-sm" data-testid="replicable-time-ago">
    <span class="gl-px-2" :class="{ 'gl-border-r-solid gl-border-r-1': showDivider }">
      <gl-sprintf :message="$options.i18n.timeAgoString">
        <template #label>
          <span>{{ label }}</span>
        </template>
        <template #timeAgo>
          <time-ago v-if="dateString" :time="dateString" tooltip-placement="top" />
          <span v-else>{{ defaultText }}</span>
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>
