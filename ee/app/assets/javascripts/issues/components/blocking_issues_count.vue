<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['hasBlockedIssuesFeature'],
  props: {
    blockingIssuesCount: {
      type: Number,
      required: false,
      default: null,
    },
    isListItem: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    showBlockingIssuesCount() {
      return this.hasBlockedIssuesFeature && this.blockingIssuesCount > 0;
    },
    tag() {
      return this.isListItem ? 'li' : 'span';
    },
  },
};
</script>

<template>
  <component :is="tag" v-if="showBlockingIssuesCount" v-gl-tooltip :title="__('Blocking issues')">
    <gl-icon name="issue-block" />
    {{ blockingIssuesCount }}
  </component>
</template>
