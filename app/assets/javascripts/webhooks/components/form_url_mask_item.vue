<script>
import { GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
  },
  props: {
    index: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    sensitiveInputId() {
      return `webhook-url-mask-item-sensitive-${this.index}`;
    },
    previewInputId() {
      return `webhook-url-mask-item-prview-${this.index}`;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-flex-end gl-gap-3 gl-mb-5">
    <gl-form-group
      :label="s__('Webhooks|Sensitive portion of URL')"
      :label-for="sensitiveInputId"
      class="gl-flex-grow-1 gl-mb-0"
    >
      <gl-form-input :id="sensitiveInputId" />
    </gl-form-group>
    <gl-form-group
      :label="s__('Webhooks|How it looks in the UI')"
      :label-for="previewInputId"
      class="gl-flex-grow-1 gl-mb-0"
    >
      <gl-form-input :id="previewInputId" />
    </gl-form-group>
    <gl-button icon="remove" />
  </div>
</template>
