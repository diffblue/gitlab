<script>
import { GlFormGroup, GlButton, GlFormInput } from '@gitlab/ui';
import autofocusonshow from '~/vue_shared/directives/autofocusonshow';

export default {
  name: 'AddIssuableResourceLinkForm',
  components: {
    GlFormGroup,
    GlButton,
    GlFormInput,
  },
  directives: {
    autofocusonshow,
  },
  props: {
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      linkTextValue: '',
      linkValue: '',
    };
  },
  computed: {
    isSubmitButtonDisabled() {
      return this.linkValue.length === 0 || this.isSubmitting;
    },
  },
  methods: {
    onFormCancel() {
      this.linkValue = '';
      this.linkTextValue = '';
      this.$emit('add-issuable-resource-link-form-cancel');
    },
    focusLinkTextInput() {
      this.$refs.linkTextInput.$el.focus();
    },
  },
};
</script>

<template>
  <form @submit.prevent>
    <gl-form-group label="Text (Optional)">
      <gl-form-input
        ref="linkTextInput"
        v-model="linkTextValue"
        data-testid="link-text-input"
        type="text"
      />
    </gl-form-group>
    <gl-form-group label="Link">
      <gl-form-input v-model="linkValue" data-testid="link-value-input" type="text" />
    </gl-form-group>
    <div class="gl-mt-5 gl-clearfix">
      <gl-button
        category="primary"
        variant="confirm"
        data-testid="add-button"
        :disabled="isSubmitButtonDisabled"
        :loading="isSubmitting"
        type="submit"
        class="gl-float-left"
      >
        {{ __('Add') }}
      </gl-button>
      <gl-button class="gl-float-right" @click="onFormCancel">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </form>
</template>
