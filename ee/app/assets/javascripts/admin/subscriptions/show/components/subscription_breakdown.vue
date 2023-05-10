<script>
import { mapState, mapActions } from 'vuex';
import { GlButton, GlModalDirective, GlModal } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { createAlert } from '~/alert';
import { __, sprintf } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import SubscriptionDetailsHistory from 'jh_else_ee/admin/subscriptions/show/components/subscription_details_history.vue';
import {
  addActivationCode,
  licensedToHeaderText,
  subscriptionDetailsHeaderText,
  subscriptionTypes,
} from '../constants';
import SubscriptionActivationBanner from './subscription_activation_banner.vue';
import SubscriptionActivationModal from './subscription_activation_modal.vue';
import SubscriptionDetailsCard from './subscription_details_card.vue';
import SubscriptionDetailsUserInfo from './subscription_details_user_info.vue';

export const subscriptionDetailsFields = ['id', 'plan', 'lastSync', 'startsAt', 'expiresAt'];
export const licensedToFields = ['name', 'email', 'company'];

export const i18n = Object.freeze({
  addActivationCode,
  licensedToHeaderText,
  subscriptionDetailsHeaderText,
  removeLicense: __('Remove license'),
  removeLicenseConfirmSaaS: sprintf(
    __(
      'This change will remove %{strongOpen}ALL%{strongClose} Premium and Ultimate features for %{strongOpen}ALL%{strongClose} SaaS customers and make tests start failing.',
    ),
    { strongOpen: '<strong>', strongClose: '</strong>' },
    false,
  ),
  removeLicenseConfirm: __('Are you sure you want to remove the license?'),
  removeLicenseButtonLabel: __('Remove license'),
  cancel: __('Cancel'),
});

export default {
  name: 'SubscriptionBreakdown',
  directives: {
    GlModalDirective,
    SafeHtml,
  },
  components: {
    GlButton,
    GlModal,
    SubscriptionActivationBanner,
    SubscriptionActivationModal,
    SubscriptionDetailsCard,
    SubscriptionDetailsHistory,
    SubscriptionDetailsUserInfo,
    SubscriptionSyncNotifications: () => import('./subscription_sync_notifications.vue'),
    UserCalloutDismisser,
  },
  inject: ['licenseRemovePath', 'subscriptionActivationBannerCalloutName'],
  props: {
    subscription: {
      type: Object,
      required: true,
    },
    subscriptionList: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      licensedToFields,
      subscriptionDetailsFields,
      activationModalVisible: false,
    };
  },
  computed: {
    ...mapState(['breakdown']),
    licenseError() {
      return this.breakdown.licenseError;
    },
    hasAsyncActivity() {
      return this.breakdown.hasAsyncActivity;
    },
    canRemoveLicense() {
      return this.licenseRemovePath;
    },
    hasSubscription() {
      return Boolean(Object.keys(this.subscription).length);
    },
    hasSubscriptionHistory() {
      return Boolean(this.subscriptionList.length);
    },
    shouldShowFooter() {
      return this.canRemoveLicense;
    },
    shouldShowNotifications() {
      return this.breakdown.shouldShowNotifications;
    },
    subscriptionHistory() {
      return this.hasSubscriptionHistory ? this.subscriptionList : [this.subscription];
    },
    isLegacySubscription() {
      return this.hasSubscription && this.subscription.type === subscriptionTypes.LEGACY_LICENSE;
    },
  },
  watch: {
    licenseError(error, prevError) {
      if (!error || error === prevError) {
        return;
      }

      this.showAlert(error);
    },
  },
  methods: {
    ...mapActions(['removeLicense']),
    showActivationModal() {
      this.activationModalVisible = true;
    },
    showAlert(errorMsg) {
      createAlert({ message: errorMsg });
    },
  },
  i18n,
  activateSubscriptionModal: {
    id: uniqueId('subscription-activation-modal-'),
  },
  removeLicenseModal: {
    id: uniqueId('remove-license-modal-'),
    title: i18n.removeLicense,
    actionCancel: {
      text: i18n.cancel,
    },
    actionPrimary: {
      text: i18n.removeLicense,
      attributes: { variant: 'danger', 'data-qa-selector': 'confirm_remove_license' },
    },
  },
  isDotCom: gon.dot_com,
};
</script>

<template>
  <div>
    <subscription-activation-modal
      v-if="hasSubscription"
      v-model="activationModalVisible"
      :modal-id="$options.activateSubscriptionModal.id"
      v-on="$listeners"
    />
    <user-callout-dismisser :feature-name="subscriptionActivationBannerCalloutName">
      <template #default="{ dismiss, shouldShowCallout }">
        <subscription-activation-banner
          v-if="isLegacySubscription && shouldShowCallout"
          class="mb-4"
          @activate-subscription="showActivationModal"
          @close="dismiss"
        />
      </template>
    </user-callout-dismisser>
    <subscription-sync-notifications v-if="shouldShowNotifications" class="gl-mb-4" />
    <section class="row gl-mb-5">
      <div class="col-md-6 gl-mb-5">
        <subscription-details-card
          class="gl-h-full"
          :details-fields="subscriptionDetailsFields"
          :header-text="$options.i18n.subscriptionDetailsHeaderText"
          :subscription="subscription"
          data-testid="subscription-details"
          data-qa-selector="subscription_details"
        >
          <template v-if="shouldShowFooter" #footer>
            <div
              class="gl-display-flex gl-flex-wrap gl-align-items-flex-start gl-justify-content-space-between"
            >
              <div>
                <gl-button
                  v-gl-modal-directive="$options.removeLicenseModal.id"
                  category="secondary"
                  :loading="hasAsyncActivity"
                  :title="$options.i18n.removeLicenseButtonLabel"
                  :aria-label="$options.i18n.removeLicenseButtonLabel"
                  variant="danger"
                  class="gl-mr-3"
                  data-testid="license-remove-action"
                  data-qa-selector="remove_license"
                >
                  {{ $options.i18n.removeLicense }}
                </gl-button>
                <gl-modal
                  :modal-id="$options.removeLicenseModal.id"
                  v-bind="$options.removeLicenseModal"
                  @primary="removeLicense"
                >
                  <div
                    v-if="$options.isDotCom"
                    v-safe-html="$options.i18n.removeLicenseConfirmSaaS"
                  ></div>
                  <br />
                  <div>{{ $options.i18n.removeLicenseConfirm }}</div>
                </gl-modal>
              </div>
              <gl-button
                v-gl-modal-directive="$options.activateSubscriptionModal.id"
                category="secondary"
                variant="confirm"
                class="gl-mr-3 gl-mb-3 gl-lg-mb-0"
                data-testid="subscription-activate-subscription-action"
              >
                {{ $options.i18n.addActivationCode }}
              </gl-button>
            </div>
          </template>
        </subscription-details-card>
      </div>

      <div class="col-md-6 gl-mb-5">
        <subscription-details-card
          class="gl-h-full"
          :details-fields="licensedToFields"
          :header-text="$options.i18n.licensedToHeaderText"
          :subscription="subscription"
        />
      </div>
    </section>
    <subscription-details-user-info v-if="hasSubscription" :subscription="subscription" />
    <subscription-details-history
      v-if="hasSubscription"
      :current-subscription-id="subscription.id"
      :subscription-list="subscriptionHistory"
    />
  </div>
</template>
