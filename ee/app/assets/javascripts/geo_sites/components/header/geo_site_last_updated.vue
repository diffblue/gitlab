<script>
import { GlPopover, GlLink, GlIcon, GlSprintf } from '@gitlab/ui';
import {
  HELP_SITE_HEALTH_URL,
  GEO_TROUBLESHOOTING_URL,
  STATUS_DELAY_THRESHOLD_MS,
} from 'ee/geo_sites/constants';
import { s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'GeoSiteLastUpdated',
  i18n: {
    troubleshootText: s__('Geo|Consult Geo troubleshooting information'),
    learnMoreText: s__('Geo|Learn more about Geo site statuses'),
    timeAgoMainText: s__('Geo|Updated %{timeAgo}'),
    timeAgoPopoverText: s__(`Geo|Site's status was updated %{timeAgo}.`),
  },
  components: {
    GlPopover,
    GlLink,
    GlIcon,
    GlSprintf,
    TimeAgo,
  },
  props: {
    statusCheckTimestamp: {
      type: Number,
      required: true,
    },
    primary: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isSyncStale() {
      const elapsedMilliseconds = Math.abs(this.statusCheckTimestamp - Date.now());
      return elapsedMilliseconds > STATUS_DELAY_THRESHOLD_MS;
    },
    syncHelp() {
      if (this.isSyncStale) {
        return {
          text: this.$options.i18n.troubleshootText,
          link: GEO_TROUBLESHOOTING_URL,
        };
      }

      return {
        text: this.$options.i18n.learnMoreText,
        link: HELP_SITE_HEALTH_URL,
      };
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <span class="gl-text-gray-500" data-testid="last-updated-main-text">
      <gl-sprintf :message="$options.i18n.timeAgoMainText">
        <template #timeAgo>
          <time-ago :time="statusCheckTimestamp" />
        </template>
      </gl-sprintf>
    </span>
    <gl-icon
      ref="lastUpdated"
      tabindex="0"
      name="question-o"
      class="gl-text-blue-600 gl-cursor-pointer gl-ml-2"
    />
    <gl-popover :target="() => $refs.lastUpdated.$el" placement="top">
      <p class="gl-font-base" data-testid="geo-last-updated-text">
        <gl-sprintf :message="$options.i18n.timeAgoPopoverText">
          <template #timeAgo>
            <time-ago :time="statusCheckTimestamp" />
          </template>
        </gl-sprintf>
      </p>
      <gl-link :href="syncHelp.link" target="_blank">{{ syncHelp.text }}</gl-link>
    </gl-popover>
  </div>
</template>
