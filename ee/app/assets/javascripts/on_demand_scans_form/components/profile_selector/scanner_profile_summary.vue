<script>
import { SCAN_TYPE_LABEL } from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/constants';
import SummaryCell from './summary_cell.vue';

export default {
  name: 'DastScannerProfileSummary',
  components: {
    SummaryCell,
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
  <div class="row">
    <summary-cell
      :class="{ 'gl-text-red-500': hasConflict }"
      :label="s__('DastProfiles|Scan mode')"
      :value="$options.SCAN_TYPE_LABEL[profile.scanType]"
    />
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
  </div>
</template>
