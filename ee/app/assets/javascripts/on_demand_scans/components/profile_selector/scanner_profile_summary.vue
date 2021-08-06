<script>
import { SCAN_TYPE_LABEL } from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/constants';
import ProfileSelectorSummaryCell from './summary_cell.vue';

export default {
  name: 'DastScannerProfileSummary',
  components: {
    ProfileSelectorSummaryCell,
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
};
</script>

<template>
  <div>
    <div class="row">
      <profile-selector-summary-cell
        :class="{ 'gl-text-red-500': hasConflict }"
        :label="s__('DastProfiles|Scan mode')"
        :value="$options.SCAN_TYPE_LABEL[profile.scanType]"
      />
    </div>
    <div class="row">
      <profile-selector-summary-cell
        :label="s__('DastProfiles|Spider timeout')"
        :value="n__('%d minute', '%d minutes', profile.spiderTimeout || 0)"
      />
      <profile-selector-summary-cell
        :label="s__('DastProfiles|Target timeout')"
        :value="n__('%d second', '%d seconds', profile.targetTimeout || 0)"
      />
    </div>
    <div class="row">
      <profile-selector-summary-cell
        :label="s__('DastProfiles|AJAX spider')"
        :value="profile.useAjaxSpider ? __('On') : __('Off')"
      />
      <profile-selector-summary-cell
        :label="s__('DastProfiles|Debug messages')"
        :value="
          profile.showDebugMessages
            ? s__('DastProfiles|Show debug messages')
            : s__('DastProfiles|Hide debug messages')
        "
      />
    </div>
  </div>
</template>
