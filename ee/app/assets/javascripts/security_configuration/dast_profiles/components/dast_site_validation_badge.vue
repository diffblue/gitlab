<script>
import { GlBadge } from '@gitlab/ui';
import {
  DAST_SITE_VALIDATION_STATUS as STATUS,
  DAST_SITE_VALIDATION_STATUS_PROPS,
} from 'ee/security_configuration/dast_site_validation/constants';

const validationStatusToBadgeVariantMap = {
  [STATUS.NONE]: 'neutral',
  [STATUS.INPROGRESS]: 'info',
  [STATUS.PENDING]: 'info',
  [STATUS.FAILED]: 'warning',
  [STATUS.PASSED]: 'success',
};

export default {
  name: 'DastSiteValidationBadge',
  components: {
    GlBadge,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    variant() {
      return validationStatusToBadgeVariantMap[this.status];
    },
    label() {
      return DAST_SITE_VALIDATION_STATUS_PROPS[this.status].labelText;
    },
  },
};
</script>

<template>
  <gl-badge size="sm" :variant="variant">
    {{ label }}
  </gl-badge>
</template>
