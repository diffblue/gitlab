<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-form-group
    :label="__('Your password')"
    :label-description="
      __(
        'To approve this merge request, please enter your password. This project requires all approvals to be authenticated.',
      )
    "
  >
    <gl-form-input
      type="password"
      :value="value"
      :placeholder="__('Password')"
      @input="(e) => $emit('input', e)"
    />
  </gl-form-group>
</template>
