<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import statusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';

export default {
  components: {
    GlIcon,
    statusIcon,
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
  <div class="media">
    <status-icon status="warning" show-disabled-button />
    <div class="media-body">
      <span class="bold">{{
        __('Merge unavailable: merge requests are read-only in a secondary Geo node.')
      }}</span>
      <a
        v-gl-tooltip
        :href="mr.geoSecondaryHelpPath"
        :title="__('About this feature')"
        target="_blank"
        rel="noopener noreferrer nofollow"
      >
        <gl-icon name="question-o" />
      </a>
    </div>
  </div>
</template>
