<script>
import { GlDropdown, GlDropdownItem, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  directives: { GlTooltip },
  inject: { searchPath: { default: '' } },
  i18n: {
    moreActions: __('More actions'),
    searchLabel: s__('FeatureFlags|Search code references'),
  },
};
</script>
<template>
  <gl-dropdown
    v-if="searchPath"
    v-gl-tooltip
    icon="ellipsis_v"
    text-sr-only
    :title="$options.i18n.moreActions"
    :text="$options.i18n.moreActions"
    category="secondary"
    no-caret
    right
  >
    <gl-dropdown-item :href="searchPath" target="_blank">
      {{ $options.i18n.searchLabel }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
