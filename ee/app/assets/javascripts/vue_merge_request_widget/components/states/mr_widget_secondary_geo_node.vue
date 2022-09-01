<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import StateContainer from '~/vue_merge_request_widget/components/state_container.vue';

export default {
  components: {
    GlIcon,
    StateContainer,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <state-container :mr="mr" status="failed">
    <span class="gl-font-weight-bold">
      {{ __('Merge unavailable: merge requests are read-only in a secondary Geo node.') }}
    </span>
    <a
      v-gl-tooltip
      :href="mr.geoSecondaryHelpPath"
      :title="__('About this feature')"
      target="_blank"
      rel="noopener noreferrer nofollow"
    >
      <gl-icon name="question-o" />
    </a>
  </state-container>
</template>
