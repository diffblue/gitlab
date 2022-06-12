<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { extendTrial, reactivateTrial } from 'ee/api/subscriptions_api';
import createFlash from '~/flash';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import { sprintf, __ } from '~/locale';
import { i18n, TRIAL_ACTION_EXTEND, TRIAL_ACTIONS } from '../constants';

export default {
  name: 'ExtendReactivateTrialButton',
  components: { GlButton, GlModal },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    namespaceId: {
      type: Number,
      required: true,
    },
    action: {
      type: String,
      required: true,
      default: TRIAL_ACTION_EXTEND,
      validator: (value) => TRIAL_ACTIONS.includes(value),
    },
    planName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    i18nContext() {
      return this.action === TRIAL_ACTION_EXTEND
        ? this.$options.i18n.extend
        : this.$options.i18n.reactivate;
    },
    modalText() {
      return sprintf(this.i18nContext.modalText, {
        action: this.actionName,
        planName: sprintf(this.$options.i18n.planName, { planName: this.planName }),
      });
    },
    actionPrimary() {
      return {
        text: this.i18nContext.buttonText,
      };
    },
    actionSecondary() {
      return {
        text: __('Cancel'),
      };
    },
  },
  methods: {
    async submit() {
      this.isLoading = true;
      this.$refs.modal.hide();

      const action = this.action === TRIAL_ACTION_EXTEND ? extendTrial : reactivateTrial;

      await action(this.namespaceId)
        .then(() => {
          refreshCurrentPage();
        })
        .catch((error) => {
          createFlash({
            message: this.i18nContext.trialActionError,
            captureError: true,
            error,
          });
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
  i18n,
};
</script>

<template>
  <div>
    <gl-button v-gl-modal.extend-trial :loading="isLoading" category="primary" variant="confirm">
      {{ i18nContext.buttonText }}
    </gl-button>
    <gl-modal
      ref="modal"
      modal-id="extend-trial"
      :title="i18nContext.buttonText"
      :action-primary="actionPrimary"
      :action-secondary="actionSecondary"
      data-testid="extend-reactivate-trial-modal"
      @primary="submit"
    >
      {{ modalText }}
    </gl-modal>
  </div>
</template>
