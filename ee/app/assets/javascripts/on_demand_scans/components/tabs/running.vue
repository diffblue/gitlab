<script>
import { __, s__ } from '~/locale';
import BaseTab from './base_tab.vue';

export default {
  components: {
    BaseTab,
  },
  i18n: {
    title: __('Running'),
    emptyStateTitle: s__('OnDemandScans|There are no running scans.'),
    emptyStateText: s__(
      'OnDemandScans|%{learnMoreLinkStart}Lean more about on-demand scans%{learnMoreLinkEnd}.',
    ),
  },
};
</script>

<template>
  <base-tab
    :title="$options.i18n.title"
    :empty-state-title="$options.i18n.emptyStateTitle"
    :empty-state-text="$options.i18n.emptyStateText"
    v-bind="$attrs"
  />
</template>
