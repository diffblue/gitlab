<script>
import { GlTooltipDirective } from '@gitlab/ui';
import getIncidentStateQuery from 'ee/graphql_shared/queries/get_incident_state.query.graphql';
import { STATUS_CLOSED } from '~/issues/constants';
import { formatTime, calculateRemainingMilliseconds } from '~/lib/utils/datetime_utility';
import { s__, sprintf } from '~/locale';
import { isValidSlaDueAt } from './utils';

export default {
  i18n: {
    achievedSLAText: s__('IncidentManagement|Achieved SLA'),
    missedSLAText: s__('IncidentManagement|Missed SLA'),
    longTitle: s__('IncidentManagement|%{hours} hours, %{minutes} minutes remaining'),
    shortTitle: s__('IncidentManagement|%{minutes} minutes remaining'),
  },
  // Refresh the timer display every 15 minutes.
  REFRESH_INTERVAL: 15 * 60 * 1000,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  apollo: {
    issueState: {
      query: getIncidentStateQuery,
      variables() {
        return {
          iid: this.issueIid,
          fullPath: this.projectPath,
        };
      },
      skip() {
        return this.remainingTime > 0;
      },
      update(data) {
        return data?.project?.issue?.state;
      },
    },
  },
  props: {
    slaDueAt: {
      type: String, // ISODateString
      required: false,
      default: null,
    },
    issueIid: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      issueState: null,
      clientRemainingTime: null,
    };
  },
  computed: {
    hasNoTimeRemaining() {
      return this.remainingTime === 0;
    },
    isClosed() {
      return this.issueState === STATUS_CLOSED;
    },
    remainingTime() {
      return this.clientRemainingTime ?? calculateRemainingMilliseconds(this.slaDueAt);
    },
    shouldShow() {
      return isValidSlaDueAt(this.slaDueAt);
    },
    hasNoTimeRemainingText() {
      if (this.isClosed) {
        return this.$options.i18n.achievedSLAText;
      }

      return this.$options.i18n.missedSLAText;
    },
    slaText() {
      if (this.hasNoTimeRemaining) {
        return this.hasNoTimeRemainingText;
      }

      const remainingDuration = formatTime(this.remainingTime);

      // remove the seconds portion of the string
      return remainingDuration.substring(0, remainingDuration.length - 3);
    },
    slaTitle() {
      if (this.hasNoTimeRemaining) {
        return this.hasNoTimeRemainingText;
      }

      const minutes = Math.floor(this.remainingTime / 1000 / 60) % 60;
      const hours = Math.floor(this.remainingTime / 1000 / 60 / 60);

      if (hours > 0) {
        return sprintf(this.$options.i18n.longTitle, { hours, minutes });
      }
      return sprintf(this.$options.i18n.shortTitle, { minutes });
    },
  },
  mounted() {
    this.timer = setInterval(this.refreshTime, this.$options.REFRESH_INTERVAL);
  },
  beforeDestroy() {
    clearTimeout(this.timer);
  },
  methods: {
    refreshTime() {
      if (this.remainingTime > this.$options.REFRESH_INTERVAL) {
        this.clientRemainingTime = this.remainingTime - this.$options.REFRESH_INTERVAL;
      } else {
        clearTimeout(this.timer);
        this.clientRemainingTime = 0;
      }
    },
  },
};
</script>
<template>
  <span v-if="shouldShow" v-gl-tooltip :title="slaTitle">
    {{ slaText }}
  </span>
</template>
