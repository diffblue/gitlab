<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  CONNECTIVITY_ERROR,
  howToActivateSubscription,
  INVALID_CODE_ERROR,
  SUBSCRIPTION_NOT_FOUND_SERVER_ERROR,
  SUBSCRIPTION_OVERAGES_SERVER_ERROR_REGEX,
  SUBSCRIPTION_INSUFFICIENT_TRUE_UP_SERVER_ERROR_REGEX,
  EXPIRED_LICENSE_SERVER_ERROR,
  supportLink,
} from '../constants';

export const testIds = Object.freeze({
  SUBSCRIPTION_ACTIVATION_ROOT: 'SUBSCRIPTION_ACTIVATION_ROOT',
  CONNECTIVITY_ERROR_ALERT: 'CONNECTIVITY_ERROR_ALERT',
  SUBSCRIPTION_NOT_FOUND_ERROR_ALERT: 'SUBSCRIPTION_NOT_FOUND_ERROR_ALERT',
  SUBSCRIPTION_OVERAGES_ERROR_ALERT: 'SUBSCRIPTION_OVERAGES_ERROR_ALERT',
  TRUE_UP_OVERAGES_ERROR_ALERT: 'TRUE_UP_OVERAGES_ERROR_ALERT',
  EXPIRED_ERROR_ALERT: 'EXPIRED_ERROR_ALERT',
  INVALID_ACTIVATION_ERROR_ALERT: 'INVALID_ACTIVATION_ERROR_ALERT',
  GENERAL_ERROR_ALERT: 'GENERAL_ERROR_ALERT',
});

export const i18n = Object.freeze({
  howToActivateSubscription,
  CONNECTIVITY_ERROR_TITLE: s__('SuperSonics|Cannot activate instance due to a connectivity issue'),
  CONNECTIVITY_ERROR_MESSAGE: s__(
    'SuperSonics|To activate your subscription, your instance needs to connect to GitLab. %{learnMoreLinkStart}Learn more%{learnMoreLinkEnd}.',
  ),
  SUBSCRIPTION_OVERAGES_ERROR_TITLE: s__(
    'SuperSonics|Activation not possible due to seat mismatch',
  ),
  SUBSCRIPTION_OVERAGES_ERROR_MESSAGE: s__(
    'SuperSonics|Your current GitLab installation has %{userCount} active %{userCountUsers}, which exceeds your new subscription seat count of %{licenseUserCount} by %{overageCount}. To activate your new subscription, %{purchaseLinkStart}purchase%{purchaseLinkEnd} an additional %{overageCount} %{overageCountSeats}, or %{deactivateLinkStart}deactivate%{deactivateLinkEnd} or %{blockLinkStart}block%{blockLinkEnd} %{overageCount} %{overageCountUsers}. For further assistance, contact %{licenseSupportLinkStart}GitLab support%{licenseSupportLinkEnd}.',
  ),
  TRUE_UP_OVERAGES_ERROR_TITLE: s__(
    'SuperSonics|Activation not possible due to true-up value mismatch',
  ),
  TRUE_UP_OVERAGES_ERROR_MESSAGE: s__(
    'SuperSonics|You have applied a true-up for %{trueUpQuantity} %{trueUpQuantityUsers} but you need one for %{expectedTrueUpQuantity} %{expectedTrueUpQuantityUsers}. To pay for seat overages, contact your sales representative. For further assistance, contact %{licenseSupportLinkStart}GitLab support%{licenseSupportLinkEnd}.',
  ),
  SUBSCRIPTION_NOT_FOUND_ERROR_TITLE: s__('SuperSonics|Your subscription cannot be located'),
  SUBSCRIPTION_NOT_FOUND_ERROR_MESSAGE: s__(
    'SuperSonics|You may have entered an expired or ineligible activation code. To request a new activation code, %{purchaseSubscriptionLinkStart}purchase a new subscription%{purchaseSubscriptionLinkEnd} or %{supportLinkStart}contact GitLab Support%{supportLinkEnd} for further assistance.',
  ),
  EXPIRED_LICENSE_ERROR_TITLE: s__('SuperSonics|Your subscription is expired'),
  EXPIRED_LICENSE_ERROR_MESSAGE: s__(
    'SuperSonics|You can %{purchaseSubscriptionLinkStart}purchase a new subscription%{purchaseSubscriptionLinkEnd} and try again. If you need further assistance, please %{supportLinkStart}contact GitLab Support%{supportLinkEnd}.',
  ),
  GENERAL_ACTIVATION_ERROR_TITLE: s__(
    'SuperSonics|An error occurred while adding your subscription',
  ),
  GENERAL_ACTIVATION_ERROR_MESSAGE: s__(
    'SuperSonics|Learn more about %{activationLinkStart}activating your subscription%{activationLinkEnd}. If you need further assistance, %{supportLinkStart}contact GitLab Support%{supportLinkEnd}.',
  ),
  INVALID_ACTIVATION_CODE: s__(
    'SuperSonics|The activation code is not valid. Please make sure to copy it exactly from the Customers Portal or confirmation email. Learn more about %{linkStart}activating your subscription%{linkEnd}.',
  ),
});

export const links = Object.freeze({
  purchaseSubscriptionLink: 'https://about.gitlab.com/pricing/',
  supportLink,
  licenseSupportLink:
    'https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=360000071293',
  subscriptionActivationHelpLink: helpPagePath('user/admin_area/license.html'),
  troubleshootingHelpLink: helpPagePath('/user/admin_area/license.html', {
    anchor: 'cannot-activate-instance-due-to-connectivity-error',
  }),
  addSeats: 'https://docs.gitlab.com/ee/subscriptions/self_managed/#add-seats-to-a-subscription',
  deactivateUser:
    'https://docs.gitlab.com/ee/user/admin_area/moderate_users.html#deactivate-a-user',
  blockUser: 'https://docs.gitlab.com/ee/user/admin_area/moderate_users.html#block-a-user',
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
    hasSubscriptionNotFoundError() {
      return this.error === SUBSCRIPTION_NOT_FOUND_SERVER_ERROR;
    },
    hasSubscriptionOveragesError() {
      return SUBSCRIPTION_OVERAGES_SERVER_ERROR_REGEX.test(this.error);
    },
    subscriptionOveragesErrorValues() {
      const [
        ,
        ,
        userCount,
        licenseUserCount,
        overageCount,
      ] = SUBSCRIPTION_OVERAGES_SERVER_ERROR_REGEX.exec(this.error);
      return { userCount, licenseUserCount, overageCount };
    },
    hasTrueUpOveragesError() {
      return SUBSCRIPTION_INSUFFICIENT_TRUE_UP_SERVER_ERROR_REGEX.test(this.error);
    },
    trueUpOveragesErrorValues() {
      const [
        ,
        trueUpQuantity,
        expectedTrueUpQuantity,
      ] = SUBSCRIPTION_INSUFFICIENT_TRUE_UP_SERVER_ERROR_REGEX.exec(this.error);
      return { trueUpQuantity, expectedTrueUpQuantity };
    },
    hasError() {
      return Boolean(this.error);
    },
    hasGeneralError() {
      return (
        this.hasError &&
        !this.hasConnectivityIssueError &&
        !this.hasInvalidCodeError &&
        !this.hasExpiredLicenseError &&
        !this.hasSubscriptionNotFoundError &&
        !this.hasSubscriptionOveragesError &&
        !this.hasTrueUpOveragesError
      );
    },
  },
  testIds,
  i18n,
  links,
};
</script>

<template>
  <div v-if="hasError" :data-testid="$options.testIds.SUBSCRIPTION_ACTIVATION_ROOT">
    <gl-alert
      v-if="hasConnectivityIssueError"
      variant="danger"
      :title="$options.i18n.CONNECTIVITY_ERROR_TITLE"
      :dismissible="false"
      :data-testid="$options.testIds.CONNECTIVITY_ERROR_ALERT"
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
      v-if="hasSubscriptionOveragesError"
      variant="danger"
      :title="$options.i18n.SUBSCRIPTION_OVERAGES_ERROR_TITLE"
      :dismissible="false"
      :data-testid="$options.testIds.SUBSCRIPTION_OVERAGES_ERROR_ALERT"
    >
      <gl-sprintf :message="$options.i18n.SUBSCRIPTION_OVERAGES_ERROR_MESSAGE">
        <template #userCount>{{ subscriptionOveragesErrorValues.userCount }}</template>
        <template #userCountUsers>{{
          n__('user', 'users', subscriptionOveragesErrorValues.userCount)
        }}</template>
        <template #licenseUserCount>{{
          subscriptionOveragesErrorValues.licenseUserCount
        }}</template>
        <template #overageCount>{{ subscriptionOveragesErrorValues.overageCount }}</template>
        <template #overageCountSeats>{{
          n__('seat', 'seats', subscriptionOveragesErrorValues.overageCount)
        }}</template>
        <template #overageCountUsers>{{
          n__('user', 'users', subscriptionOveragesErrorValues.overageCount)
        }}</template>
        <template #purchaseLink="{ content }">
          <gl-link
            :href="$options.links.addSeats"
            target="_blank"
            class="gl-text-decoration-none!"
            >{{ content }}</gl-link
          >
        </template>
        <template #deactivateLink="{ content }">
          <gl-link
            :href="$options.links.deactivateUser"
            target="_blank"
            class="gl-text-decoration-none!"
            >{{ content }}</gl-link
          >
        </template>
        <template #blockLink="{ content }">
          <gl-link
            :href="$options.links.blockUser"
            target="_blank"
            class="gl-text-decoration-none!"
            >{{ content }}</gl-link
          >
        </template>
        <template #licenseSupportLink="{ content }">
          <gl-link
            :href="$options.links.licenseSupportLink"
            target="_blank"
            class="gl-text-decoration-none!"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </gl-alert>
    <gl-alert
      v-if="hasTrueUpOveragesError"
      variant="danger"
      :title="$options.i18n.TRUE_UP_OVERAGES_ERROR_TITLE"
      :dismissible="false"
      :data-testid="$options.testIds.TRUE_UP_OVERAGES_ERROR_ALERT"
    >
      <gl-sprintf :message="$options.i18n.TRUE_UP_OVERAGES_ERROR_MESSAGE">
        <template #trueUpQuantity>{{ trueUpOveragesErrorValues.trueUpQuantity }}</template>
        <template #trueUpQuantityUsers>{{
          n__('user', 'users', trueUpOveragesErrorValues.trueUpQuantity)
        }}</template>
        <template #expectedTrueUpQuantity>{{
          trueUpOveragesErrorValues.expectedTrueUpQuantity
        }}</template>
        <template #expectedTrueUpQuantityUsers>{{
          n__('user', 'users', trueUpOveragesErrorValues.expectedTrueUpQuantity)
        }}</template>
        <template #licenseSupportLink="{ content }">
          <gl-link
            :href="$options.links.licenseSupportLink"
            target="_blank"
            class="gl-text-decoration-none!"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </gl-alert>
    <gl-alert
      v-if="hasSubscriptionNotFoundError"
      variant="danger"
      :title="$options.i18n.SUBSCRIPTION_NOT_FOUND_ERROR_TITLE"
      :dismissible="false"
      :data-testid="$options.testIds.SUBSCRIPTION_NOT_FOUND_ERROR_ALERT"
    >
      <gl-sprintf :message="$options.i18n.SUBSCRIPTION_NOT_FOUND_ERROR_MESSAGE">
        <template #purchaseSubscriptionLink="{ content }">
          <gl-link
            :href="$options.links.purchaseSubscriptionLink"
            target="_blank"
            class="gl-text-decoration-none!"
            >{{ content }}</gl-link
          > </template
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
      v-if="hasExpiredLicenseError"
      variant="danger"
      :title="$options.i18n.EXPIRED_LICENSE_ERROR_TITLE"
      :dismissible="false"
      :data-testid="$options.testIds.EXPIRED_ERROR_ALERT"
    >
      <gl-sprintf :message="$options.i18n.EXPIRED_LICENSE_ERROR_MESSAGE">
        <template #purchaseSubscriptionLink="{ content }">
          <gl-link
            :href="$options.links.purchaseSubscriptionLink"
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
      :data-testid="$options.testIds.INVALID_ACTIVATION_ERROR_ALERT"
    >
      <gl-sprintf :message="$options.i18n.INVALID_ACTIVATION_CODE">
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
      :data-testid="$options.testIds.GENERAL_ERROR_ALERT"
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
