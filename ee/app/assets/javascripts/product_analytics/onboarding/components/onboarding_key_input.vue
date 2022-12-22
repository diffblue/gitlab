<script>
import { GlFormGroup, GlFormInputGroup, GlFormInput } from '@gitlab/ui';

import { __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  name: 'ProductAnalyticsOnboardingKeyInput',
  components: { ClipboardButton, GlFormGroup, GlFormInputGroup, GlFormInput },
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
  i18n: {
    copyToClipboard: __('Copy to clipboard'),
  },
};
</script>

<template>
  <gl-form-group :label="label" :label-description="description">
    <gl-form-input-group>
      <gl-form-input :value="value" size="lg" readonly />
      <template #append>
        <clipboard-button :text="value" :title="$options.i18n.copyToClipboard" />
      </template>
    </gl-form-input-group>
  </gl-form-group>
</template>
