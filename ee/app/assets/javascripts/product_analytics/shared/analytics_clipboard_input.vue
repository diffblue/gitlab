<script>
import { GlButton, GlFormGroup, GlFormInputGroup, GlFormInput, GlTooltip } from '@gitlab/ui';
import { __ } from '~/locale';

export const TOOLTIP_ALERT_TIMEOUT = 2000;

export default {
  name: 'ProductAnalyticsClipboardInput',
  components: { GlButton, GlTooltip, GlFormGroup, GlFormInputGroup, GlFormInput },
  props: {
    label: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      tooltipText: this.$options.i18n.copyToClipboard,
      hint: '',
    };
  },
  methods: {
    async copyValue() {
      try {
        await navigator.clipboard.writeText(this.value);
        this.tooltipText = this.$options.i18n.copied;
      } catch (error) {
        this.hint = this.$options.i18n.failedToCopy;

        return;
      }

      setTimeout(() => {
        this.tooltipText = this.$options.i18n.copyToClipboard;
      }, TOOLTIP_ALERT_TIMEOUT);
    },
    getTooltipTarget() {
      const { copyButton } = this.$refs;

      return copyButton?.$el;
    },
  },
  i18n: {
    copyValue: __('Copy value'),
    copyToClipboard: __('Copy to clipboard'),
    copied: __('Copied'),
    failedToCopy: __('Copy failed. Please manually copy the value.'),
  },
};
</script>

<template>
  <gl-form-group
    class="gl-mb-0"
    :label="label"
    :label-description="description"
    :description="hint"
  >
    <gl-form-input-group>
      <gl-form-input :value="value" size="lg" readonly />
      <template #append>
        <gl-button
          ref="copyButton"
          :aria-label="$options.i18n.copyValue"
          icon="copy-to-clipboard"
          @click="copyValue"
        />
        <gl-tooltip :title="tooltipText" :target="getTooltipTarget" triggers="hover" />
      </template>
    </gl-form-input-group>
  </gl-form-group>
</template>
