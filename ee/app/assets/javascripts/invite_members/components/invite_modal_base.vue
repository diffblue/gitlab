<script>
import { GlLink } from '@gitlab/ui';
import { partition, isString } from 'lodash';
import * as Sentry from '@sentry/browser';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import InviteModalBase from '~/invite_members/components/invite_modal_base.vue';
import apolloProvider from '../provider';
import {
  OVERAGE_MODAL_LINK,
  OVERAGE_MODAL_TITLE,
  OVERAGE_MODAL_BACK_BUTTON,
  OVERAGE_MODAL_CONTINUE_BUTTON,
  OVERAGE_MODAL_LINK_TEXT,
  overageModalInfoText,
  overageModalInfoWarning,
} from '../constants';
import { checkOverage } from '../check_overage';
import { fetchSubscription } from '../get_subscription_data';
import { fetchUserIdsFromGroup } from '../utils';
import getSubscriptionEligibility from '../subscription_eligible.customer.query.graphql';

const OVERAGE_CONTENT_SLOT = 'overage-content';
const EXTRA_SLOTS = [
  {
    key: OVERAGE_CONTENT_SLOT,
    attributes: {
      class: 'invite-modal-content',
      'data-testid': 'invite-modal-overage-content',
    },
  },
];

export default {
  components: {
    GlLink,
    InviteModalBase,
  },
  apolloProvider,
  mixins: [glFeatureFlagsMixin()],
  inheritAttrs: false,
  props: {
    name: {
      type: String,
      required: true,
    },
    modalTitle: {
      type: String,
      required: true,
    },
    rootGroupId: {
      type: String,
      required: false,
      default: '',
    },
    newUsersToInvite: {
      type: Array,
      required: false,
      default: () => [],
    },
    newGroupToInvite: {
      type: Number,
      required: false,
      default: null,
    },
    submitDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    reachedLimit: {
      type: Boolean,
      required: false,
      default: false,
    },
    invalidFeedbackMessage: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      hasOverage: false,
      totalUserCount: null,
      subscriptionSeats: 0,
      namespaceId: parseInt(this.rootGroupId, 10),
      eligibleForSeatUsageAlerts: false,
      isLoading: false,
      actualFeedbackMessage: this.invalidFeedbackMessage,
    };
  },
  computed: {
    currentSlot() {
      if (this.showOverageModal) {
        return OVERAGE_CONTENT_SLOT;
      }

      // Use CE default
      return undefined;
    },
    showOverageModal() {
      return this.hasOverage && this.enabledOverageCheck && !this.actualFeedbackMessage;
    },
    submitDisabledEE() {
      if (this.showOverageModal) {
        return false;
      }

      // Use CE default
      return this.submitDisabled;
    },
    enabledOverageCheck() {
      return this.glFeatures.overageMembersModal;
    },
    modalInfo() {
      if (this.totalUserCount) {
        const infoText = overageModalInfoText(this.subscriptionSeats);
        const infoWarning = overageModalInfoWarning(this.totalUserCount, this.name);

        return `${infoText} ${infoWarning}`;
      }
      return '';
    },
    modalTitleOverride() {
      return this.showOverageModal ? OVERAGE_MODAL_TITLE : this.modalTitle;
    },
    overageModalButtons() {
      if (this.showOverageModal) {
        return {
          submit: OVERAGE_MODAL_CONTINUE_BUTTON,
          cancel: OVERAGE_MODAL_BACK_BUTTON,
        };
      }

      // Use CE default
      return {};
    },
  },
  watch: {
    invalidFeedbackMessage(newValue) {
      this.hasOverage = false;
      this.actualFeedbackMessage = newValue;
    },
  },
  methods: {
    getPassthroughListeners() {
      // This gets the listeners we don't manually handle here
      // so we can pass them through to the CE invite_modal_base.vue
      const { reset, submit, ...listeners } = this.$listeners;

      return listeners;
    },
    onReset() {
      // don't reopen the overage modal
      this.hasOverage = false;
      this.actualFeedbackMessage = '';

      this.$emit('reset');
    },
    onSubmit(args) {
      if (this.reachedLimit) return;

      if (this.enabledOverageCheck && !this.hasOverage) {
        this.actualFeedbackMessage = '';
        this.checkEligibility(args);
      } else {
        this.emitSubmit(args);
      }
    },
    checkEligibility(args) {
      this.isLoading = true;
      this.$apollo.addSmartQuery('eligibleForSeatUsageAlerts', {
        query: getSubscriptionEligibility,
        variables() {
          return {
            namespaceId: this.namespaceId,
          };
        },
        update(data) {
          return data.subscription?.eligibleForSeatUsageAlerts;
        },
        result({ data }) {
          if (data?.subscription?.eligibleForSeatUsageAlerts) {
            this.checkAndSubmit(args);
            return;
          }
          // we don't want to block the flow if API response has unexpected data
          this.emitSubmit(args);
          this.isLoading = false;
        },
        error(er) {
          this.isLoading = false;
          Sentry.captureException(er);
        },
      });
    },
    async checkAndSubmit(args) {
      let usersToAddById = [];
      let usersToInviteByEmail = [];

      const subscriptionData = await fetchSubscription(this.namespaceId);
      this.subscriptionSeats = subscriptionData.subscriptionSeats;

      if (this.newGroupToInvite) {
        usersToAddById = await fetchUserIdsFromGroup(this.newGroupToInvite);
      } else {
        [usersToInviteByEmail, usersToAddById] = this.partitionNewUsersToInvite();
      }

      const isGuestRole = args.accessLevel === this.$attrs['access-levels'].Guest;

      const { hasOverage, usersOverage } = checkOverage(subscriptionData, {
        isGuestRole,
        usersToAddById,
        usersToInviteByEmail,
      });
      this.isLoading = false;
      this.hasOverage = hasOverage;

      if (hasOverage) {
        this.totalUserCount = usersOverage;
      } else {
        this.emitSubmit(args);
      }
    },
    emitSubmit({ accessLevel, expiresAt } = {}) {
      this.$emit('submit', { accessLevel, expiresAt });
    },
    passthroughSlotNames() {
      return Object.keys(this.$scopedSlots || {});
    },
    partitionNewUsersToInvite() {
      const [usersToInviteByEmail, usersToAddById] = partition(
        this.newUsersToInvite,
        ({ id }) => isString(id) && id.includes('user-defined-token'),
      );

      return [usersToInviteByEmail.map(({ name }) => name), usersToAddById.map(({ id }) => id)];
    },
    onCancel() {
      if (this.showOverageModal) {
        this.hasOverage = false;
      }
    },
  },
  i18n: {
    OVERAGE_MODAL_TITLE,
    OVERAGE_MODAL_LINK,
    OVERAGE_MODAL_BACK_BUTTON,
    OVERAGE_MODAL_CONTINUE_BUTTON,
    OVERAGE_MODAL_LINK_TEXT,
  },
  OVERAGE_CONTENT_SLOT,
  EXTRA_SLOTS,
};
</script>

<template>
  <invite-modal-base
    v-bind="$attrs"
    :name="name"
    :submit-button-text="overageModalButtons.submit"
    :cancel-button-text="overageModalButtons.cancel"
    :modal-title="modalTitleOverride"
    :current-slot="currentSlot"
    :extra-slots="$options.EXTRA_SLOTS"
    :submit-disabled="submitDisabledEE"
    :prevent-cancel-default="showOverageModal"
    :reached-limit="reachedLimit"
    :is-loading="isLoading"
    :invalid-feedback-message="actualFeedbackMessage"
    @reset="onReset"
    @submit="onSubmit"
    @cancel="onCancel"
    v-on="getPassthroughListeners()"
  >
    <template #[$options.OVERAGE_CONTENT_SLOT]>
      {{ modalInfo }}
      <gl-link :href="$options.i18n.OVERAGE_MODAL_LINK" target="_blank">{{
        $options.i18n.OVERAGE_MODAL_LINK_TEXT
      }}</gl-link>
    </template>
    <template v-for="(_, slot) of $scopedSlots" #[slot]="scope">
      <slot :name="slot" v-bind="scope"></slot>
    </template>
  </invite-modal-base>
</template>
