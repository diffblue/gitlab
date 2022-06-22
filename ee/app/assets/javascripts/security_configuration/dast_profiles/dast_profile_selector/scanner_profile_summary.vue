<script>
import { SCAN_TYPE_LABEL } from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/constants';
import { SCANNER_TYPE } from 'ee/on_demand_scans/constants';
import ScanTypeBadge from 'ee/security_configuration/dast_profiles/components/dast_scan_type_badge.vue';
import DastProfileSummaryCard from './dast_profile_summary_card.vue';
import SummaryCell from './summary_cell.vue';

export default {
  name: 'DastScannerProfileSummary',
  components: {
    DastProfileSummaryCard,
    SummaryCell,
    ScanTypeBadge,
  },
  props: {
    profile: {
      type: Object,
      required: true,
    },
    hasConflict: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  SCAN_TYPE_LABEL,
  SCANNER_TYPE,
};
</script>

<template>
  <dast-profile-summary-card
    :profile-type="$options.SCANNER_TYPE"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <template #title>
      {{ profile.profileName }}
    </template>
    <template #summary>
      <summary-cell
        :class="{ 'gl-text-red-500': hasConflict }"
        :label="s__('DastProfiles|Scan mode')"
        ><scan-type-badge :scan-type="profile.scanType"
      /></summary-cell>
      <summary-cell
        :label="s__('DastProfiles|Spider timeout')"
        :value="n__('%d minute', '%d minutes', profile.spiderTimeout || 0)"
      />
      <summary-cell
        :label="s__('DastProfiles|Target timeout')"
        :value="n__('%d second', '%d seconds', profile.targetTimeout || 0)"
      />
      <summary-cell
        :label="s__('DastProfiles|AJAX spider')"
        :value="profile.useAjaxSpider ? __('On') : __('Off')"
      />
      <summary-cell
        :label="s__('DastProfiles|Debug messages')"
        :value="
          profile.showDebugMessages
            ? s__('DastProfiles|Show debug messages')
            : s__('DastProfiles|Hide debug messages')
        "
      />
    </template>
  </dast-profile-summary-card>
</template>
