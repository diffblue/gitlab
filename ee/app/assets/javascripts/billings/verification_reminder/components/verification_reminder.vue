<script>
import { GlAlert, GlSprintf, GlButton } from '@gitlab/ui';
import Tracking from '~/tracking';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import AccountVerificationModal from 'ee/billings/components/account_verification_modal.vue';
import {
  FEATURE_NAME,
  DOCS_LINK,
  I18N,
  EVENT_LABEL,
  MOUNTED_EVENT,
  DISMISS_EVENT,
  OPEN_DOCS_EVENT,
  START_VERIFICATION_EVENT,
  SUCCESSFUL_VERIFICATION_EVENT,
} from '../constants';

export default {
  components: {
    UserCalloutDismisser,
    AccountVerificationModal,
    GlAlert,
    GlSprintf,
    GlButton,
  },
  mixins: [Tracking.mixin({ label: EVENT_LABEL })],
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
    this.track(MOUNTED_EVENT);
  },
  methods: {
    handleDismiss() {
      this.track(DISMISS_EVENT);
      this.$refs.calloutDismisser.dismiss();
    },
    showModal() {
      this.track(START_VERIFICATION_EVENT);
      this.accountVerificationModalVisible = true;
    },
    clickOpenDocs() {
      this.track(OPEN_DOCS_EVENT);
    },
    handleSuccessfulVerification() {
      this.track(SUCCESSFUL_VERIFICATION_EVENT);
      this.accountVerificationModalVisible = false;
      this.$refs.calloutDismisser.dismiss();
      this.shouldRenderSuccess = true;
    },
  },
  i18n: I18N,
  featureName: FEATURE_NAME,
  docsLink: DOCS_LINK,
};
</script>

<template>
  <div>
    <user-callout-dismisser ref="calloutDismisser" :feature-name="$options.featureName" skip-query>
      <template #default="{ shouldShowCallout }">
        <gl-alert
          v-if="shouldShowCallout"
          ref="warningAlert"
          :title="$options.i18n.warningAlert.title"
          variant="warning"
          @dismiss="handleDismiss"
        >
          <gl-sprintf :message="$options.i18n.warningAlert.message">
            <template #validateLink="{ content }">
              <gl-button ref="validateLink" variant="link" @click="showModal">
                {{ content }}
              </gl-button>
            </template>
            <template #docsLink="{ content }">
              <gl-button
                ref="docsLink"
                variant="link"
                :href="$options.docsLink"
                target="_blank"
                @click="clickOpenDocs"
              >
                {{ content }}
              </gl-button>
            </template>
          </gl-sprintf>
        </gl-alert>
      </template>
    </user-callout-dismisser>
    <account-verification-modal
      v-model="accountVerificationModalVisible"
      :iframe-url="iframeUrl"
      :allowed-origin="allowedOrigin"
      @success="handleSuccessfulVerification"
    />
    <gl-alert
      v-if="shouldRenderSuccess"
      ref="successAlert"
      variant="success"
      :title="$options.i18n.successAlert.title"
      @dismiss="shouldRenderSuccess = false"
    >
      {{ $options.i18n.successAlert.message }}
    </gl-alert>
  </div>
</template>
