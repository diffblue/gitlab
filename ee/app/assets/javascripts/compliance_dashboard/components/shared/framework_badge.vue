<script>
import { GlBadge, GlLabel } from '@gitlab/ui';
import { s__ } from '~/locale';

import { FRAMEWORK_BADGE_SIZE_MD, FRAMEWORK_BADGE_SIZES } from '../../constants';

export default {
  name: 'ComplianceFrameworkBadge',
  components: {
    GlLabel,
    GlBadge,
  },
  props: {
    framework: {
      type: Object,
      required: true,
    },
    size: {
      type: String,
      required: false,
      default: FRAMEWORK_BADGE_SIZE_MD,
      validator: (val) => FRAMEWORK_BADGE_SIZES.includes(val),
    },
    showDefault: {
      type: Boolean,
      required: false,
      default: true,
    },
    closeable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    showDefaultBadge() {
      return this.showDefault && this.framework.default;
    },
  },
  i18n: {
    default: s__('ComplianceFrameworks|default'),
  },
};
</script>
<template>
  <div>
    <gl-label
      data-qa-selector="framework_label"
      :background-color="framework.color"
      :description="framework.description"
      :title="framework.name"
      :size="size"
      :show-close-button="closeable"
      @close="$emit('close')"
    />
    <gl-badge v-if="showDefaultBadge" :size="size" variant="info" data-qa-selector="framework_badge"
      >{{ $options.i18n.default }}
    </gl-badge>
  </div>
</template>
