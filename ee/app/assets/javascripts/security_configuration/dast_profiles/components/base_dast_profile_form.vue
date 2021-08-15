<script>
import { GlAlert, GlButton, GlForm, GlModal } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';

export default {
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlModal,
  },
  props: {
    profile: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    mutation: {
      type: Object,
      required: true,
    },
    mutationType: {
      type: String,
      required: true,
    },
    mutationVariables: {
      type: Object,
      required: true,
    },
    showHeader: {
      type: Boolean,
      required: false,
      default: true,
    },
    formTouched: {
      type: Boolean,
      required: false,
      default: false,
    },
    isPolicyProfile: {
      type: Boolean,
      required: false,
      default: false,
    },
    blockSubmit: {
      type: Boolean,
      required: false,
      default: false,
    },
    modalProps: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      showAlert: false,
      errors: [],
    };
  },
  methods: {
    onSubmit() {
      this.$emit('submit');

      if (this.blockSubmit) {
        return;
      }

      this.isLoading = true;
      this.hideErrors();

      this.saveProfile();
    },
    saveProfile() {
      this.$apollo
        .mutate({
          mutation: this.mutation,
          variables: { input: this.mutationVariables },
        })
        .then(
          ({
            data: {
              [this.mutationType]: { id, errors = [] },
            },
          }) => {
            if (errors.length > 0) {
              this.showErrors(errors);
              this.isLoading = false;
            } else {
              this.$emit('success', {
                id,
              });
            }
          },
        )
        .catch((exception) => {
          Sentry.captureException(exception);
          this.showErrors();
          this.isLoading = false;
        });
    },
    onCancelClicked() {
      if (!this.formTouched) {
        this.discard();
      } else {
        this.$refs[this.$options.modalId].show();
      }
    },
    discard() {
      this.$emit('cancel');
    },
    showErrors(errors = []) {
      this.errors = errors;
      this.showAlert = true;
    },
    hideErrors() {
      this.errors = [];
      this.showAlert = false;
    },
  },
  modalId: 'discardConfirmationModal',
};
</script>

<template>
  <gl-form novalidate @submit.prevent="onSubmit">
    <h2 v-if="showHeader" class="gl-mb-6" data-testid="header">
      <slot name="title"></slot>
    </h2>

    <gl-alert
      v-if="isPolicyProfile"
      data-testid="dast-policy-profile-alert"
      variant="info"
      class="gl-mb-5"
      :dismissible="false"
    >
      <slot name="policy-profile-notice"></slot>
    </gl-alert>

    <gl-alert
      v-if="showAlert"
      variant="danger"
      class="gl-mb-5"
      data-testid="dast-profile-form-alert"
      @dismiss="hideErrors"
    >
      <slot name="error-message"></slot>
      <ul v-if="errors.length" class="gl-mt-3 gl-mb-0">
        <li v-for="error in errors" :key="error" v-text="error"></li>
      </ul>
    </gl-alert>

    <slot></slot>

    <hr class="gl-border-gray-100" />

    <gl-button
      :disabled="isPolicyProfile"
      :loading="isLoading"
      type="submit"
      variant="confirm"
      class="js-no-auto-disable"
      data-testid="dast-profile-form-submit-button"
    >
      {{ s__('DastProfiles|Save profile') }}
    </gl-button>
    <gl-button
      class="gl-ml-2"
      data-testid="dast-profile-form-cancel-button"
      @click="onCancelClicked"
    >
      {{ __('Cancel') }}
    </gl-button>

    <gl-modal
      :ref="$options.modalId"
      :modal-id="$options.modalId"
      v-bind="modalProps"
      ok-variant="danger"
      body-class="gl-display-none"
      data-testid="dast-profile-form-cancel-modal"
      @ok="discard"
    />
  </gl-form>
</template>
