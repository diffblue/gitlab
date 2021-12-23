<script>
import { GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import ScanTypeBadge from 'ee/security_configuration/dast_profiles/components/dast_scan_type_badge.vue';
import dastProfilesQuery from '../../graphql/dast_profiles.query.graphql';
import { SAVED_TAB_TABLE_FIELDS, LEARN_MORE_TEXT } from '../../constants';
import BaseTab from './base_tab.vue';

export default {
  query: dastProfilesQuery,
  components: {
    GlIcon,
    BaseTab,
    ScanTypeBadge,
  },
  tableFields: SAVED_TAB_TABLE_FIELDS,
  i18n: {
    title: s__('OnDemandScans|Scan library'),
    emptyStateTitle: s__('OnDemandScans|There are no saved scans.'),
    emptyStateText: LEARN_MORE_TEXT,
  },
};
</script>

<template>
  <base-tab
    :query="$options.query"
    :query-variables="$options.queryVariables"
    :title="$options.i18n.title"
    :fields="$options.tableFields"
    :empty-state-title="$options.i18n.emptyStateTitle"
    :empty-state-text="$options.i18n.emptyStateText"
    v-bind="$attrs"
  >
    <template #after-name="item"><gl-icon name="branch" /> {{ item.branch.name }}</template>

    <template #cell(scanType)="{ value }">
      <scan-type-badge :scan-type="value" />
    </template>
  </base-tab>
</template>
