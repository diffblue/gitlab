<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  CONNECTIVITY_ERROR,
  connectivityErrorAlert,
  connectivityIssue,
  generalActivationErrorMessage,
  generalActivationErrorTitle,
  howToActivateSubscription,
  INVALID_CODE_ERROR,
  invalidActivationCode,
  supportLink,
} from '../constants';

export const troubleshootingHelpLink = helpPagePath('user/admin_area/license.html', {
  anchor: 'troubleshooting',
});
export const subscriptionActivationHelpLink = helpPagePath('user/admin_area/license.html');

export default {
  name: 'SubscriptionActivationErrors',
  i18n: {
    connectivityIssueTitle: connectivityIssue,
    connectivityIssueSubtitle: connectivityErrorAlert.subtitle,
    connectivityIssueHelpText: connectivityErrorAlert.helpText,
    generalActivationErrorMessage,
    generalActivationErrorTitle,
    howToActivateSubscription,
    invalidActivationCode,
  },
  links: {
    subscriptionActivationHelpLink,
    supportLink,
    troubleshootingHelpLink,
  },
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  props: {
    error: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasConnectivityIssueError() {
      return this.error === CONNECTIVITY_ERROR;
    },
    hasError() {
      return this.error;
    },
    hasGeneralError() {
      return ![CONNECTIVITY_ERROR, INVALID_CODE_ERROR].includes(this.error);
    },
    hasInvalidCodeError() {
      return this.error === INVALID_CODE_ERROR;
    },
  },
};
</script>

<template>
  <div v-if="hasError" data-testid="root">
    <gl-alert
      v-if="hasConnectivityIssueError"
      variant="danger"
      :title="$options.i18n.connectivityIssueTitle"
      :dismissible="false"
      data-testid="connectivity-error-alert"
    >
      <gl-sprintf :message="$options.i18n.connectivityIssueSubtitle">
        <template #link="{ content }">
          <gl-link
            :href="$options.links.subscriptionActivationHelpLink"
            target="_blank"
            class="gl-text-decoration-none!"
            >{{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
      <gl-sprintf :message="$options.i18n.connectivityIssueHelpText">
        <template #link="{ content }">
          <gl-link
            :href="$options.links.troubleshootingHelpLink"
            target="_blank"
            class="gl-text-decoration-none!"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </gl-alert>
    <gl-alert
      v-if="hasInvalidCodeError"
      variant="danger"
      :title="$options.i18n.generalActivationErrorTitle"
      :dismissible="false"
      data-testid="invalid-activation-error-alert"
    >
      <gl-sprintf :message="$options.i18n.invalidActivationCode">
        <template #link="{ content }">
          <gl-link :href="$options.links.subscriptionActivationHelpLink" target="_blank">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <gl-alert
      v-if="hasGeneralError"
      variant="danger"
      :title="$options.i18n.generalActivationErrorTitle"
      :dismissible="false"
      data-testid="general-error-alert"
    >
      <gl-sprintf :message="$options.i18n.generalActivationErrorMessage">
        <template #activationLink="{ content }">
          <gl-link :href="$options.links.subscriptionActivationHelpLink" target="_blank">{{
            content
          }}</gl-link>
        </template>
        <template #supportLink="{ content }">
          <gl-link :href="$options.links.supportLink" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
  </div>
</template>
