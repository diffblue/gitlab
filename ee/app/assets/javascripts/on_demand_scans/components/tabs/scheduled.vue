<script>
import { GlIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import DastScanSchedule from 'ee/security_configuration/dast_profiles/components/dast_scan_schedule.vue';
import scheduledDastProfilesQuery from '../../graphql/scheduled_dast_profiles.query.graphql';
import {
  SCHEDULED_TAB_TABLE_FIELDS,
  LEARN_MORE_TEXT,
  MAX_DAST_PROFILES_COUNT,
} from '../../constants';
import BaseTab from './base_tab.vue';

export default {
  query: scheduledDastProfilesQuery,
  components: {
    GlIcon,
    BaseTab,
    DastScanSchedule,
  },
  inject: ['timezones'],
  maxItemsCount: MAX_DAST_PROFILES_COUNT,
  tableFields: SCHEDULED_TAB_TABLE_FIELDS,
  i18n: {
    title: __('Scheduled'),
    emptyStateTitle: s__('OnDemandScans|There are no scheduled scans.'),
    emptyStateText: LEARN_MORE_TEXT,
  },
  methods: {
    getTimezoneCode(timezone) {
      return this.timezones.find(({ identifier }) => identifier === timezone)?.abbr;
    },
  },
};
</script>

<template>
  <base-tab
    :max-items-count="$options.maxItemsCount"
    :query="$options.query"
    :title="$options.i18n.title"
    :fields="$options.tableFields"
    :empty-state-title="$options.i18n.emptyStateTitle"
    :empty-state-text="$options.i18n.emptyStateText"
    v-bind="$attrs"
  >
    <template #cell(nextRun)="{ value: { date, time, timezone } }">
      <div class="gl-white-space-nowrap"><gl-icon :size="12" name="calendar" /> {{ date }}</div>
      <div class="gl-text-secondary gl-white-space-nowrap">
        <gl-icon :size="12" name="clock" /> {{ time }} {{ getTimezoneCode(timezone) }}
      </div>
    </template>

    <template #cell(dastProfileSchedule)="{ value }">
      <dast-scan-schedule :schedule="value" />
    </template>
  </base-tab>
</template>
