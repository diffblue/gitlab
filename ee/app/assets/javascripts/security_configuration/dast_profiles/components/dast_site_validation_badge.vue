<script>
import { GlBadge } from '@gitlab/ui';
import {
  DAST_SITE_VALIDATION_STATUS,
  DAST_SITE_VALIDATION_STATUS_PROPS,
  VALIDATION_STATUS_TO_BADGE_VARIANT_MAP,
} from 'ee/security_configuration/dast_site_validation/constants';

export default {
  name: 'DastSiteValidationBadge',
  components: {
    GlBadge,
  },
  props: {
    status: {
      type: String,
      required: true,
      validator: (value) => Object.values(DAST_SITE_VALIDATION_STATUS).includes(value),
    },
  },
  computed: {
    variant() {
      return VALIDATION_STATUS_TO_BADGE_VARIANT_MAP[this.status];
    },
    label() {
      return DAST_SITE_VALIDATION_STATUS_PROPS[this.status]?.labelText;
    },
  },
};
</script>

<template>
  <gl-badge size="sm" :variant="variant">
    {{ label }}
  </gl-badge>
</template>
