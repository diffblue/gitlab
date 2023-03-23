<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import AccountVerificationModal from './account_verification_modal.vue';

const i18n = {
  successAlert: {
    title: s__('Billings|Your account has been validated'),
    text: s__(
      "Billings|You'll now be able to take advantage of free CI/CD minutes on shared runners.",
    ),
  },
  dangerAlert: {
    title: s__('Billings|User validation required'),
    text: s__(`Billings|To use free CI/CD minutes on shared runners, you’ll need to validate your account with a credit card. If you prefer not to provide one, you can run pipelines by bringing your own runners and disabling shared runners for your project.
    This is required to discourage and reduce abuse on GitLab infrastructure.
    %{strongStart}GitLab will not charge your card, it will only be used for validation.%{strongEnd} %{linkStart}Learn more%{linkEnd}.`),
    primaryButtonText: s__('Billings|Validate account'),
  },
  pipelineVerificationLink: 'https://about.gitlab.com/blog/2021/05/17/prevent-crypto-mining-abuse/',
};

export default {
  name: 'CreditCardValidationRequiredAlert',
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    AccountVerificationModal,
  },
  mixins: [Tracking.mixin()],
  props: {
    customMessage: {
      type: String,
      default: null,
      required: false,
    },
    isFromAccountValidationEmail: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      shouldRenderSuccess: false,
      accountVerificationModalVisible: false,
    };
  },
  computed: {
    iframeUrl() {
      return gon.payment_form_url;
    },
    allowedOrigin() {
      return gon.subscriptions_url;
    },
  },
  mounted() {
    if (this.isFromAccountValidationEmail) {
      this.showModal();
    }
  },
  methods: {
    showModal() {
      this.accountVerificationModalVisible = true;
    },
    handleSuccessfulVerification() {
      if (this.isFromAccountValidationEmail) {
        this.track('successful_validation', { label: 'account_validation_email' });
      }

      this.accountVerificationModalVisible = false;
      this.shouldRenderSuccess = true;
      this.$emit('verifiedCreditCard');
    },
  },
  i18n,
};
</script>

<template>
  <div data-testid="creditCardValidationRequiredAlert">
    <gl-alert
      v-if="shouldRenderSuccess"
      variant="success"
      :title="$options.i18n.successAlert.title"
      :dismissible="false"
    >
      {{ $options.i18n.successAlert.text }}
    </gl-alert>
    <gl-alert
      v-else
      variant="danger"
      :title="$options.i18n.dangerAlert.title"
      :primary-button-text="$options.i18n.dangerAlert.primaryButtonText"
      @primaryAction="showModal"
      @dismiss="$emit('dismiss')"
    >
      <template v-if="customMessage">
        {{ customMessage }}
      </template>
      <gl-sprintf v-else :message="$options.i18n.dangerAlert.text">
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
        <template #link="{ content }">
          <gl-link :href="$options.i18n.pipelineVerificationLink">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <account-verification-modal
      v-model="accountVerificationModalVisible"
      :iframe-url="iframeUrl"
      :allowed-origin="allowedOrigin"
      @success="handleSuccessfulVerification"
    />
  </div>
</template>
