<script>
import { escape } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, sprintf } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'PipelineInfo',
  components: {
    TimeAgoTooltip,
  },
  directives: {
    SafeHtml,
  },
  props: {
    path: {
      required: true,
      type: String,
    },
    timestamp: {
      required: true,
      type: String,
    },
  },
  computed: {
    pipelineText() {
      const { path } = this;
      const body = s__(
        "Licenses|Displays licenses detected in the project that are out of compliance with the project's policies, based on the %{linkStart}latest successful%{linkEnd} scan",
      );

      const linkStart = path
        ? `<a href="${escape(path)}" target="_blank" rel="noopener noreferrer">`
        : '';
      const linkEnd = path ? '</a>' : '';

      return sprintf(body, { linkStart, linkEnd }, false);
    },
    hasFullPipelineText() {
      return Boolean(this.path && this.timestamp);
    },
  },
};
</script>

<template>
  <span v-if="hasFullPipelineText">
    <span v-safe-html="pipelineText"></span>
    <span>•</span>
    <time-ago-tooltip :time="timestamp" />
  </span>

  <span v-else v-safe-html="pipelineText"></span>
</template>
