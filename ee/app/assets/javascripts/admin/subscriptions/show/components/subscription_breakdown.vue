<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import {
  activateCloudLicense,
  licensedToHeaderText,
  manageSubscriptionButtonText,
  subscriptionSyncStatus,
  removeLicense,
  removeLicenseConfirm,
  subscriptionDetailsHeaderText,
  subscriptionTypes,
  syncSubscriptionButtonText,
} from '../constants';
import SubscriptionActivationBanner from './subscription_activation_banner.vue';
import SubscriptionActivationModal from './subscription_activation_modal.vue';
import SubscriptionDetailsCard from './subscription_details_card.vue';
import SubscriptionDetailsHistory from './subscription_details_history.vue';
import SubscriptionDetailsUserInfo from './subscription_details_user_info.vue';

export const subscriptionDetailsFields = ['id', 'plan', 'expiresAt', 'lastSync', 'startsAt'];
export const licensedToFields = ['name', 'email', 'company'];
export const modalId = 'subscription-activation-modal';

export default {
  i18n: {
    activateCloudLicense,
    licensedToHeaderText,
    manageSubscriptionButtonText,
    removeLicense,
    removeLicenseConfirm,
    subscriptionDetailsHeaderText,
    syncSubscriptionButtonText,
  },
  modal: {
    id: modalId,
  },
  name: 'SubscriptionBreakdown',
  directives: {
    GlModal: GlModalDirective,
  },
  components: {
    SubscriptionActivationBanner,
    GlButton,
    SubscriptionActivationModal,
    SubscriptionDetailsCard,
    SubscriptionDetailsHistory,
    SubscriptionDetailsUserInfo,
    SubscriptionSyncNotifications: () => import('./subscription_sync_notifications.vue'),
    UserCalloutDismisser,
  },
  inject: [
    'customersPortalUrl',
    'licenseRemovePath',
    'subscriptionSyncPath',
    'subscriptionActivationBannerCalloutName',
  ],
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
      hasAsyncActivity: false,
      licensedToFields,
      shouldShowNotifications: false,
      subscriptionSyncStatus: null,
      subscriptionDetailsFields,
      activationModalVisible: false,
    };
  },
  computed: {
    canActivateSubscription() {
      return this.isLicenseFileType;
    },
    canManageSubscription() {
      return this.customersPortalUrl && this.hasSubscription;
    },
    canSyncSubscription() {
      return this.subscriptionSyncPath && this.isCloudType;
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
    isCloudType() {
      return this.subscription.type === subscriptionTypes.CLOUD;
    },
    isLicenseFileType() {
      return this.subscription.type === subscriptionTypes.LICENSE_FILE;
    },
    shouldShowFooter() {
      return (
        this.canActivateSubscription ||
        this.canRemoveLicense ||
        this.canManageSubscription ||
        this.canSyncSubscription
      );
    },
    subscriptionHistory() {
      return this.hasSubscriptionHistory ? this.subscriptionList : [this.subscription];
    },
    syncDidFail() {
      return this.subscriptionSyncStatus === subscriptionSyncStatus.SYNC_FAILURE;
    },
  },
  methods: {
    didDismissAlert() {
      this.shouldShowNotifications = false;
    },
    showActivationModal() {
      this.activationModalVisible = true;
    },
    syncSubscription() {
      this.hasAsyncActivity = true;
      this.shouldShowNotifications = false;
      axios
        .post(this.subscriptionSyncPath)
        .then(() => {
          this.subscriptionSyncStatus = subscriptionSyncStatus.SYNC_PENDING;
        })
        .catch(() => {
          this.subscriptionSyncStatus = subscriptionSyncStatus.SYNC_FAILURE;
        })
        .finally(() => {
          this.shouldShowNotifications = true;
          this.hasAsyncActivity = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <subscription-activation-modal
      v-if="hasSubscription"
      v-model="activationModalVisible"
      :modal-id="$options.modal.id"
      v-on="$listeners"
    />
    <user-callout-dismisser
      v-if="canActivateSubscription"
      :feature-name="subscriptionActivationBannerCalloutName"
    >
      <template #default="{ dismiss, shouldShowCallout }">
        <subscription-activation-banner
          v-if="shouldShowCallout"
          class="mb-4"
          @activate-subscription="showActivationModal"
          @close="dismiss"
        />
      </template>
    </user-callout-dismisser>
    <subscription-sync-notifications
      v-if="shouldShowNotifications"
      class="mb-4"
      :sync-status="subscriptionSyncStatus"
      @info-alert-dismissed="didDismissAlert"
    />
    <section class="row gl-mb-5">
      <div class="col-md-6 gl-mb-5">
        <subscription-details-card
          class="gl-h-full"
          :details-fields="subscriptionDetailsFields"
          :header-text="$options.i18n.subscriptionDetailsHeaderText"
          :subscription="subscription"
          :sync-did-fail="syncDidFail"
          data-testid="subscription-details"
        >
          <template v-if="shouldShowFooter" #footer>
            <gl-button
              v-if="canSyncSubscription"
              category="primary"
              :loading="hasAsyncActivity"
              variant="confirm"
              data-testid="subscription-sync-action"
              @click="syncSubscription"
            >
              {{ $options.i18n.syncSubscriptionButtonText }}
            </gl-button>
            <gl-button
              v-if="canActivateSubscription"
              v-gl-modal="$options.modal.id"
              category="primary"
              variant="confirm"
              data-testid="subscription-activate-subscription-action"
            >
              {{ $options.i18n.activateCloudLicense }}
            </gl-button>
            <gl-button
              v-if="canManageSubscription"
              :href="customersPortalUrl"
              target="_blank"
              category="secondary"
              variant="confirm"
              data-testid="subscription-manage-action"
            >
              {{ $options.i18n.manageSubscriptionButtonText }}
            </gl-button>
            <gl-button
              v-if="canRemoveLicense"
              category="secondary"
              variant="danger"
              :href="licenseRemovePath"
              :data-confirm="$options.i18n.removeLicenseConfirm"
              data-method="delete"
              data-testid="license-remove-action"
              data-qa-selector="remove_license_link"
            >
              {{ $options.i18n.removeLicense }}
            </gl-button>
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
