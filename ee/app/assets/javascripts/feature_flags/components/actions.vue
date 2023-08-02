<script>
import { GlDisclosureDropdown, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  components: {
    GlDisclosureDropdown,
  },
  directives: { GlTooltip },
  inject: { searchPath: { default: '' } },
  i18n: {
    moreActions: __('More actions'),
    searchLabel: s__('FeatureFlags|Search code references'),
  },
  computed: {
    items() {
      return [
        {
          text: this.$options.i18n.searchLabel,
          href: this.searchPath,
        },
      ];
    },
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-if="searchPath"
    v-gl-tooltip
    icon="ellipsis_v"
    text-sr-only
    :items="items"
    :title="$options.i18n.moreActions"
    :toggle-text="$options.i18n.moreActions"
    category="secondary"
    no-caret
    placement="right"
  />
</template>
