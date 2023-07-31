<script>
import { GlAlert, GlTooltipDirective, GlSkeletonLoader } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  pendingMembersAlertButtonText,
  seatsAvailableText,
  seatsInSubscriptionText,
  seatsInSubscriptionTextForFreePlan,
  seatsInUseLink,
  seatsTooltipText,
  seatsTooltipTrialText,
  unlimited,
} from 'ee/usage_quotas/seats/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { sprintf, n__ } from '~/locale';
import CodeSuggestionsUsageStatisticsCard from 'ee/usage_quotas/seats/components/code_suggestions_usage_statistics_card.vue';
import StatisticsCard from 'ee/usage_quotas/components/statistics_card.vue';
import StatisticsSeatsCard from 'ee/usage_quotas/seats/components/statistics_seats_card.vue';
import SubscriptionUsageStatisticsCard from 'ee/usage_quotas/seats/components/subscription_usage_statistics_card.vue';
import SubscriptionUpgradeInfoCard from './subscription_upgrade_info_card.vue';
import SubscriptionUserList from './subscription_user_list.vue';

export default {
  name: 'SubscriptionSeats',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAlert,
    CodeSuggestionsUsageStatisticsCard,
    StatisticsCard,
    StatisticsSeatsCard,
    SubscriptionUpgradeInfoCard,
    SubscriptionUsageStatisticsCard,
    SubscriptionUserList,
    GlSkeletonLoader,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState([
      'hasError',
      'total',
      'pendingMembersPagePath',
      'pendingMembersCount',
      'seatsInSubscription',
      'seatsInUse',
      'maxSeatsUsed',
      'seatsOwed',
      'addSeatsHref',
      'hasNoSubscription',
      'maxFreeNamespaceSeats',
      'explorePlansPath',
      'hasLimitedFreePlan',
      'hasReachedFreePlanLimit',
      'activeTrial',
    ]),
    ...mapGetters(['hasFreePlan', 'isLoading']),
    pendingMembersAlertMessage() {
      return sprintf(
        n__(
          'You have %{pendingMembersCount} pending member that needs approval.',
          'You have %{pendingMembersCount} pending members that need approval.',
          this.pendingMembersCount,
        ),
        {
          pendingMembersCount: this.pendingMembersCount,
        },
      );
    },
    shouldShowPendingMembersAlert() {
      return (
        this.pendingMembersCount > 0 && this.pendingMembersPagePath && !this.hasLimitedFreePlan
      );
    },
    shouldShowSubscriptionRelatedCards() {
      return Boolean(this.glFeatures?.enableHamiltonInUsageQuotasUi) && !this.hasNoSubscription;
    },
    seatsInUsePercentage() {
      if (this.totalSeatsAvailable == null || this.activeTrial) {
        return 0;
      }

      return Math.round((this.totalSeatsInUse * 100) / this.totalSeatsAvailable);
    },
    totalSeatsAvailable() {
      if (this.hasNoSubscription) {
        return this.hasLimitedFreePlan ? this.maxFreeNamespaceSeats : null;
      }
      return this.seatsInSubscription;
    },
    totalSeatsInUse() {
      if (this.hasLimitedFreePlan) {
        return this.seatsInUse;
      }
      return this.total;
    },
    seatsInUseText() {
      if (this.hasFreePlan) {
        return this.$options.i18n.seatsInSubscriptionTextForFreePlan;
      }

      return this.hasLimitedFreePlan
        ? this.$options.i18n.seatsAvailableText
        : this.$options.i18n.seatsInSubscriptionText;
    },
    seatsInUseTooltipText() {
      if (!this.hasLimitedFreePlan) return null;
      if (this.activeTrial) return this.$options.i18n.seatsTooltipTrialText;

      return sprintf(this.$options.i18n.seatsTooltipText, { number: this.maxFreeNamespaceSeats });
    },
    displayedTotalSeats() {
      if (this.activeTrial) return this.$options.i18n.unlimited;

      return this.totalSeatsAvailable
        ? String(this.totalSeatsAvailable)
        : this.$options.i18n.unlimited;
    },
    showUpgradeInfoCard() {
      if (!this.hasNoSubscription) {
        return false;
      }
      return this.hasLimitedFreePlan;
    },
    isLoaderShown() {
      return this.isLoading || this.hasError;
    },
  },
  created() {
    this.fetchBillableMembersList();
    this.fetchGitlabSubscription();
  },
  methods: {
    ...mapActions(['fetchBillableMembersList', 'fetchGitlabSubscription']),
    navigateToPendingMembersPage() {
      visitUrl(this.pendingMembersPagePath);
    },
  },
  helpLinks: {
    seatsInUseLink,
  },
  i18n: {
    seatsInSubscriptionTextForFreePlan,
    seatsAvailableText,
    seatsInSubscriptionText,
    seatsTooltipTrialText,
    seatsTooltipText,
    unlimited,
    pendingMembersAlertButtonText,
  },
};
</script>

<template>
  <section>
    <gl-alert
      v-if="shouldShowPendingMembersAlert"
      variant="info"
      :dismissible="false"
      :primary-button-text="$options.i18n.pendingMembersAlertButtonText"
      class="gl-my-3"
      data-testid="pending-members-alert"
      data-qa-selector="pending_members_alert"
      @primaryAction="navigateToPendingMembersPage"
    >
      {{ pendingMembersAlertMessage }}
    </gl-alert>

    <div class="gl-bg-gray-10 gl-p-5">
      <div
        v-if="isLoaderShown"
        class="gl-display-grid gl-md-grid-template-columns-2 gl-gap-5"
        data-testid="skeleton-loader-cards"
      >
        <div class="gl-bg-white gl-border gl-p-5 gl-rounded-base">
          <gl-skeleton-loader :height="64">
            <rect width="140" height="30" x="5" y="0" rx="4" />
            <rect width="240" height="10" x="5" y="40" rx="4" />
            <rect width="340" height="10" x="5" y="54" rx="4" />
          </gl-skeleton-loader>
        </div>

        <div class="gl-bg-white gl-border gl-p-5 gl-rounded-base">
          <gl-skeleton-loader :height="64">
            <rect width="140" height="30" x="5" y="0" rx="4" />
            <rect width="240" height="10" x="5" y="40" rx="4" />
            <rect width="340" height="10" x="5" y="54" rx="4" />
          </gl-skeleton-loader>
        </div>
      </div>

      <div v-else class="gl-display-grid gl-md-grid-template-columns-2 gl-gap-5">
        <subscription-usage-statistics-card
          v-if="shouldShowSubscriptionRelatedCards"
          :percentage="seatsInUsePercentage"
          :usage-value="String(totalSeatsInUse)"
          :total-value="displayedTotalSeats"
        />
        <statistics-card
          v-else
          :help-link="$options.helpLinks.seatsInUseLink"
          :help-tooltip="seatsInUseTooltipText"
          :description="seatsInUseText"
          :percentage="seatsInUsePercentage"
          :usage-value="String(totalSeatsInUse)"
          :total-value="displayedTotalSeats"
          data-qa-selector="seats_in_use"
        />
        <subscription-upgrade-info-card
          v-if="showUpgradeInfoCard"
          :max-namespace-seats="maxFreeNamespaceSeats"
          :explore-plans-path="explorePlansPath"
          :active-trial="activeTrial"
        />
        <code-suggestions-usage-statistics-card v-else-if="shouldShowSubscriptionRelatedCards" />
        <statistics-seats-card
          v-else
          :seats-used="maxSeatsUsed"
          :seats-owed="seatsOwed"
          :purchase-button-link="addSeatsHref"
        />
      </div>
    </div>

    <subscription-user-list />
  </section>
</template>
