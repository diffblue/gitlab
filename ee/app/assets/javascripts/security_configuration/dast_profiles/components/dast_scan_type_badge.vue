<script>
import { GlBadge } from '@gitlab/ui';
import {
  SCAN_TYPE,
  SCAN_TYPE_LABEL,
} from 'ee/security_configuration/dast_profiles/dast_scanner_profiles/constants';

const scanTypeToBadgeVariantMap = {
  [SCAN_TYPE.ACTIVE]: 'warning',
  [SCAN_TYPE.PASSIVE]: 'neutral',
};

export default {
  name: 'DastScanTypeBadge',
  components: {
    GlBadge,
  },
  props: {
    scanType: {
      type: String,
      required: true,
      validator: (value) => Boolean(SCAN_TYPE[value]),
    },
  },
  computed: {
    variant() {
      return scanTypeToBadgeVariantMap[this.scanType];
    },
    label() {
      return SCAN_TYPE_LABEL[this.scanType].toLowerCase();
    },
  },
};
</script>

<template>
  <gl-badge size="sm" :variant="variant">
    {{ label }}
  </gl-badge>
</template>
