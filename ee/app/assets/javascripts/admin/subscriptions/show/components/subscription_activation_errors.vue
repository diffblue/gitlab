<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  CONNECTIVITY_ERROR,
  CONNECTIVITY_ERROR_TITLE,
  CONNECTIVITY_ERROR_MESSAGE,
  howToActivateSubscription,
  INVALID_CODE_ERROR,
  EXPIRED_LICENSE_SERVER_ERROR,
  invalidActivationCode,
  supportLink,
} from '../constants';

export const i18n = Object.freeze({
  EXPIRED_LICENSE_ERROR_TITLE: s__('SuperSonics|Your subscription is expired.'),
  EXPIRED_LICENSE_ERROR_MESSAGE: s__(
    'SuperSonics|You can %{purchaseSubscriptionLinkStart}purchase a new subscription%{purchaseSubscriptionLinkEnd} and try again. If you need further assistance, please %{supportLinkStart}contact GitLab Support%{supportLinkEnd}.',
  ),
  CONNECTIVITY_ERROR_TITLE,
  CONNECTIVITY_ERROR_MESSAGE,
  GENERAL_ACTIVATION_ERROR_TITLE: s__(
    'SuperSonics|An error occurred while adding your subscription.',
  ),
  GENERAL_ACTIVATION_ERROR_MESSAGE: s__(
    'SuperSonics|Learn more about %{activationLinkStart}activating your subscription%{activationLinkEnd}. If you need further assistance, %{supportLinkStart}contact GitLab Support%{supportLinkEnd}.',
  ),
  howToActivateSubscription,
  invalidActivationCode,
});

export const links = Object.freeze({
  purchaseSubscriptionLink: 'https://about.gitlab.com/pricing/',
  supportLink,
  subscriptionActivationHelpLink: helpPagePath('user/admin_area/license.html'),
  troubleshootingHelpLink: helpPagePath('/user/admin_area/license.html', {
    anchor: 'cannot-activate-instance-due-to-connectivity-error',
  }),
});

export default {
  name: 'SubscriptionActivationErrors',
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
    hasExpiredLicenseError() {
      return this.error === EXPIRED_LICENSE_SERVER_ERROR;
    },
    hasInvalidCodeError() {
      return this.error === INVALID_CODE_ERROR;
    },
    hasError() {
      return this.error;
    },
    hasGeneralError() {
      return ![CONNECTIVITY_ERROR, INVALID_CODE_ERROR, EXPIRED_LICENSE_SERVER_ERROR].includes(
        this.error,
      );
    },
  },
  i18n,
  links,
};
</script>

<template>
  <div v-if="hasError" data-testid="root">
    <gl-alert
      v-if="hasConnectivityIssueError"
      variant="danger"
      :title="$options.i18n.CONNECTIVITY_ERROR_TITLE"
      :dismissible="false"
      data-testid="connectivity-error-alert"
    >
      <gl-sprintf :message="$options.i18n.CONNECTIVITY_ERROR_MESSAGE">
        <template #learnMoreLink="{ content }">
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
      v-if="hasExpiredLicenseError"
      variant="danger"
      :title="$options.i18n.EXPIRED_LICENSE_ERROR_TITLE"
      :dismissible="false"
      data-testid="expired-error-alert"
    >
      <gl-sprintf :message="$options.i18n.EXPIRED_LICENSE_ERROR_MESSAGE">
        <template #purchaseSubscriptionLink="{ content }">
          <gl-link
            :href="$options.links.purchaseSubscriptionLinkStart"
            target="_blank"
            class="gl-text-decoration-none!"
            >{{ content }}
          </gl-link> </template
        ><template #supportLink="{ content }">
          <gl-link
            :href="$options.links.supportLink"
            target="_blank"
            class="gl-text-decoration-none!"
            >{{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <gl-alert
      v-if="hasInvalidCodeError"
      variant="danger"
      :title="$options.i18n.GENERAL_ACTIVATION_ERROR_TITLE"
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
      :title="$options.i18n.GENERAL_ACTIVATION_ERROR_TITLE"
      :dismissible="false"
      data-testid="general-error-alert"
    >
      <gl-sprintf :message="$options.i18n.GENERAL_ACTIVATION_ERROR_MESSAGE">
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
