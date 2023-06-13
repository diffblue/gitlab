<script>
import { GlButton, GlLabel, GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';

import { FRAMEWORK_BADGE_SIZE_MD, FRAMEWORK_BADGE_SIZES } from '../../constants';

export default {
  name: 'ComplianceFrameworkBadge',
  components: {
    GlLabel,
    GlButton,
    GlPopover,
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
    frameworkName() {
      return this.showDefaultBadge
        ? `${this.framework.name} (${this.$options.i18n.default})`
        : this.framework.name;
    },
    frameworkTestId() {
      return this.showDefaultBadge
        ? 'compliance-framework-default-label'
        : 'compliance-framework-label';
    },
  },
  methods: {
    editFromPopover() {
      this.$refs.popover.$emit('close');
      this.$emit('edit');
    },
  },
  i18n: {
    default: s__('ComplianceFrameworks|default'),
    edit: s__('ComplianceReport|Edit the framework'),
  },
};
</script>
<template>
  <div ref="badge">
    <gl-popover ref="popover" :target="() => $refs.label">
      <p v-if="framework.description" class="gl-text-left">{{ framework.description }}</p>
      <div class="gl-text-left">
        <gl-button
          category="tertiary"
          variant="confirm"
          class="gl-font-sm"
          @click="editFromPopover"
        >
          {{ $options.i18n.edit }}
        </gl-button>
      </div>
    </gl-popover>
    <span ref="label">
      <gl-label
        data-qa-selector="framework_label"
        :data-testid="frameworkTestId"
        :background-color="framework.color"
        :title="frameworkName"
        :size="size"
        :show-close-button="closeable"
        @close="$emit('close')"
      />
    </span>
  </div>
</template>
