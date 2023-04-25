<script>
import {
  GlAlert,
  GlAvatarLabeled,
  GlAvatarLink,
  GlBadge,
  GlButton,
  GlModal,
  GlModalDirective,
  GlIcon,
  GlPagination,
  GlTable,
  GlTooltipDirective,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';
import dateFormat from '~/lib/dateformat';
import { visitUrl } from '~/lib/utils/url_utility';
import {
  FIELDS,
  AVATAR_SIZE,
  REMOVE_BILLABLE_MEMBER_MODAL_ID,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_ID,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_TITLE,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT,
  SORT_OPTIONS,
} from 'ee/usage_quotas/seats/constants';
import { s__, __, sprintf, n__ } from '~/locale';
import SearchAndSortBar from 'ee/usage_quotas/components/search_and_sort_bar/search_and_sort_bar.vue';
import StatisticsCard from 'ee/usage_quotas/components/statistics_card.vue';
import StatisticsSeatsCard from 'ee/usage_quotas/components/statistics_seats_card.vue';
import SubscriptionUpgradeInfoCard from './subscription_upgrade_info_card.vue';
import RemoveBillableMemberModal from './remove_billable_member_modal.vue';
import SubscriptionSeatDetails from './subscription_seat_details.vue';

export default {
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAlert,
    GlAvatarLabeled,
    GlAvatarLink,
    GlBadge,
    GlButton,
    GlModal,
    GlIcon,
    GlPagination,
    GlTable,
    RemoveBillableMemberModal,
    SubscriptionSeatDetails,
    SearchAndSortBar,
    StatisticsCard,
    StatisticsSeatsCard,
    SubscriptionUpgradeInfoCard,
    GlSkeletonLoader,
  },
  computed: {
    ...mapState([
      'hasError',
      'page',
      'perPage',
      'total',
      'namespaceName',
      'namespaceId',
      'seatUsageExportPath',
      'pendingMembersPagePath',
      'pendingMembersCount',
      'billableMemberToRemove',
      'search',
      'sort',
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
      'notificationFreeUserCapEnabled',
      'activeTrial',
    ]),
    ...mapGetters(['tableItems', 'isLoading']),
    currentPage: {
      get() {
        return this.page;
      },
      set(val) {
        this.setCurrentPage(val);
      },
    },
    emptyText() {
      if (this.search?.length < 3) {
        return s__('Billing|Enter at least three characters to search.');
      }
      return s__('Billing|No users to display.');
    },
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
        this.pendingMembersCount > 0 &&
        this.pendingMembersPagePath &&
        !this.hasLimitedPlanOrInNotificationFreePlan
      );
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
      if (this.hasLimitedPlanOrInNotificationFreePlan) {
        return this.seatsInUse;
      }
      return this.total;
    },
    seatsInUseText() {
      return this.hasLimitedPlanOrInNotificationFreePlan
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
      return this.hasLimitedPlanOrInNotificationFreePlan;
    },
    hasLimitedPlanOrInNotificationFreePlan() {
      return this.hasLimitedFreePlan || this.notificationFreeUserCapEnabled;
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
    formatLastLoginAt(lastLogin) {
      return lastLogin ? dateFormat(lastLogin, 'yyyy-mm-dd HH:MM:ss') : __('Never');
    },
    ...mapActions([
      'fetchBillableMembersList',
      'fetchGitlabSubscription',
      'setBillableMemberToRemove',
      'setSearchQuery',
      'setCurrentPage',
      'setSortOption',
    ]),
    applyFilter(searchTerm) {
      this.setSearchQuery(searchTerm);
    },
    displayRemoveMemberModal(user) {
      if (user.removable) {
        this.setBillableMemberToRemove(user);
      } else {
        this.$refs.cannotRemoveModal.show();
      }
    },
    isGroupInvite(user) {
      return user.membership_type === 'group_invite';
    },
    isProjectInvite(user) {
      return user.membership_type === 'project_invite';
    },
    shouldShowDetails(item) {
      return !this.isProjectOrGroupInvite(item.user);
    },
    isProjectOrGroupInvite(user) {
      return this.isGroupInvite(user) || this.isProjectInvite(user);
    },
    navigateToPendingMembersPage() {
      visitUrl(this.pendingMembersPagePath);
    },
  },
  i18n: {
    emailNotVisibleTooltipText: s__(
      'Billing|An email address is only visible for users with public emails.',
    ),
    filterUsersPlaceholder: __('Filter users'),
    pendingMembersAlertButtonText: s__('Billing|View pending approvals'),
    seatsInSubscriptionText: s__('Billings|Seats in use / Seats in subscription'),
    seatsAvailableText: s__('Billings|Seats in use / Seats available'),
    seatsTooltipText: s__('Billings|Free groups are limited to %{number} seats.'),
    seatsTooltipTrialText: s__(
      'Billings|Free tier and trial groups can invite a maximum of 20 members per day.',
    ),
    inASeatLabel: s__('Billings|In a seat'),
    seatsInUseLink: helpPagePath('subscriptions/gitlab_com/index', {
      anchor: 'how-seat-usage-is-determined',
    }),
    unlimited: __('Unlimited'),
  },
  avatarSize: AVATAR_SIZE,
  fields: FIELDS,
  removeBillableMemberModalId: REMOVE_BILLABLE_MEMBER_MODAL_ID,
  cannotRemoveModalId: CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_ID,
  cannotRemoveModalTitle: CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_TITLE,
  cannotRemoveModalText: CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT,
  sortOptions: SORT_OPTIONS,
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
        <statistics-card
          :help-link="$options.i18n.seatsInUseLink"
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
        <statistics-seats-card
          v-else
          :seats-used="maxSeatsUsed"
          :seats-owed="seatsOwed"
          :purchase-button-link="addSeatsHref"
        />
      </div>
    </div>

    <div class="gl-bg-gray-10 gl-p-5 gl-display-flex">
      <search-and-sort-bar
        :namespace="namespaceId"
        :search-input-placeholder="$options.i18n.filterUsersPlaceholder"
        :sort-options="$options.sortOptions"
        initial-sort-by="last_activity_on_desc"
        @onFilter="applyFilter"
        @onSort="setSortOption"
      />
      <gl-button
        v-if="seatUsageExportPath"
        data-testid="export-button"
        :href="seatUsageExportPath"
        class="gl-ml-3"
      >
        {{ s__('Billing|Export list') }}
      </gl-button>
    </div>

    <gl-table
      :items="tableItems"
      :fields="$options.fields"
      :busy="isLoaderShown"
      :show-empty="true"
      data-testid="table"
      data-qa-selector="subscription_users"
      :empty-text="emptyText"
    >
      <template #cell(disclosure)="{ item, toggleDetails, detailsShowing }">
        <gl-button
          v-if="shouldShowDetails(item)"
          variant="link"
          class="gl-w-7 gl-h-7"
          :aria-label="s__('Billing|Toggle seat details')"
          :aria-expanded="detailsShowing ? 'true' : 'false'"
          :data-testid="`toggle-seat-usage-details-${item.user.id}`"
          @click="toggleDetails"
        >
          <gl-icon
            :name="detailsShowing ? 'chevron-lg-down' : 'chevron-lg-right'"
            class="gl-text-gray-900"
          />
        </gl-button>

        <span v-else class="gl-inline-block gl-w-7"></span>
      </template>

      <template #cell(user)="{ item }">
        <div class="gl-display-flex">
          <gl-avatar-link target="blank" :href="item.user.web_url" :alt="item.user.name">
            <gl-avatar-labeled
              :src="item.user.avatar_url"
              :size="$options.avatarSize"
              :label="item.user.name"
              :sub-label="item.user.username"
            >
              <template #meta>
                <gl-badge v-if="isGroupInvite(item.user)" size="sm" variant="muted">
                  {{ s__('Billing|Group invite') }}
                </gl-badge>
                <gl-badge v-if="isProjectInvite(item.user)" size="sm" variant="muted">
                  {{ s__('Billing|Project invite') }}
                </gl-badge>
              </template>
            </gl-avatar-labeled>
          </gl-avatar-link>
        </div>
      </template>

      <template #cell(email)="{ item }">
        <div data-testid="email">
          <span v-if="item.email" class="gl-text-gray-900">{{ item.email }}</span>
          <span
            v-else
            v-gl-tooltip
            :title="$options.i18n.emailNotVisibleTooltipText"
            class="gl-font-style-italic"
          >
            {{ s__('Billing|Private') }}
          </span>
        </div>
      </template>

      <template #cell(lastActivityTime)="data">
        <span data-testid="last_activity_on">
          {{ data.item.user.last_activity_on ? data.item.user.last_activity_on : __('Never') }}
        </span>
      </template>

      <template #cell(lastLoginAt)="data">
        <span data-testid="last_login_at">
          {{ formatLastLoginAt(data.item.user.last_login_at) }}
        </span>
      </template>

      <template #cell(actions)="data">
        <gl-button
          v-gl-modal="$options.removeBillableMemberModalId"
          category="secondary"
          variant="danger"
          data-testid="remove-user"
          data-qa-selector="remove_user"
          @click="displayRemoveMemberModal(data.item.user)"
        >
          {{ __('Remove user') }}
        </gl-button>
      </template>

      <template #row-details="{ item }">
        <subscription-seat-details :seat-member-id="item.user.id" />
      </template>
    </gl-table>

    <gl-pagination
      v-if="currentPage"
      v-model="currentPage"
      :per-page="perPage"
      :total-items="total"
      align="center"
      class="gl-mt-5"
    />

    <remove-billable-member-modal
      v-if="billableMemberToRemove"
      :modal-id="$options.removeBillableMemberModalId"
    />

    <gl-modal
      ref="cannotRemoveModal"
      :modal-id="$options.cannotRemoveModalId"
      :title="$options.cannotRemoveModalTitle"
      :action-primary="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        text: __('Okay'),
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      static
    >
      <p>
        {{ $options.cannotRemoveModalText }}
      </p>
    </gl-modal>
  </section>
</template>
<style>
.b-table-has-details > td:first-child {
  border-bottom: none;
}
.b-table-details > td {
  padding-top: 0 !important;
  padding-bottom: 0 !important;
}
</style>
