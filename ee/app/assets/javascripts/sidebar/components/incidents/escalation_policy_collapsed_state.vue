<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { i18nPolicyText } from '../../constants';

export default {
  i18n: i18nPolicyText,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    policyText() {
      return this.value ? this.$options.i18n.paged : this.$options.i18n.none;
    },
    tooltipText() {
      const policyName = this.value || this.$options.i18n.none;

      return `${this.$options.i18n.title}: ${policyName}`;
    },
  },
};
</script>

<template>
  <div
    v-gl-tooltip.left.viewport
    :title="tooltipText"
    class="sidebar-collapsed-icon"
    data-testid="sidebar-collapsed-attribute-title"
  >
    <gl-icon :aria-label="$options.i18n.title" name="mobile" />
    <span class="collapse-truncated-title gl-pt-2 gl-px-3 gl-font-sm">
      {{ policyText }}
    </span>
  </div>
</template>
