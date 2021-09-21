<script>
import { GlModal } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  activateLabel,
  activateSubscription,
  subscriptionActivationInsertCode,
  SUBSCRIPTION_ACTIVATION_FAILURE_EVENT,
  SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT,
} from '../constants';
import SubscriptionActivationErrors from './subscription_activation_errors.vue';
import SubscriptionActivationForm from './subscription_activation_form.vue';

export default {
  actionCancel: { text: __('Cancel') },
  actionPrimary: {
    text: activateLabel,
  },
  bodyText: subscriptionActivationInsertCode,
  title: activateSubscription,
  name: 'SubscriptionActivationModal',
  components: {
    GlModal,
    SubscriptionActivationErrors,
    SubscriptionActivationForm,
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    visible: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      error: null,
      activationListeners: {
        [SUBSCRIPTION_ACTIVATION_FAILURE_EVENT]: this.handleActivationFailure,
        [SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT]: this.handleActivationSuccess,
      },
    };
  },
  methods: {
    handleActivationFailure(error) {
      this.error = error;
    },
    handleActivationSuccess(license) {
      this.$emit('change', false);
      // Pass on event to parent listeners
      this.$emit(SUBSCRIPTION_ACTIVATION_SUCCESS_EVENT, license);
    },
    handleChange(event) {
      this.$emit('change', event);
    },
    handlePrimary() {
      this.$refs.form.submit();
    },
    removeError() {
      this.error = null;
    },
  },
};
</script>

<template>
  <gl-modal
    :visible="visible"
    :modal-id="modalId"
    :title="$options.title"
    :action-cancel="$options.actionCancel"
    :action-primary="$options.actionPrimary"
    @primary.prevent="handlePrimary"
    @hidden="removeError"
    @change="handleChange"
  >
    <subscription-activation-errors v-if="error" class="mb-4" :error="error" />
    <p>{{ $options.bodyText }}</p>
    <subscription-activation-form
      ref="form"
      :hide-submit-button="true"
      v-on="activationListeners"
    />
  </gl-modal>
</template>
