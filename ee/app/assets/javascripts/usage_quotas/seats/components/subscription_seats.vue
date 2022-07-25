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
  GlToggle,
  GlSprintf,
} from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import Tracking from '~/tracking';
import { helpPagePath } from '~/helpers/help_page_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import { getCookie, setCookie } from '~/lib/utils/common_utils';
import {
  STANDARD_FIELDS,
  FIELDS_WITH_MEMBERSHIP_TOGGLE,
  AVATAR_SIZE,
  REMOVE_BILLABLE_MEMBER_MODAL_ID,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_ID,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_TITLE,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT,
  SORT_OPTIONS,
  MEMBER_ACTIVE_STATE,
  MEMBER_AWAITING_STATE,
  DISMISS_SEATS_ALERT_COOKIE_NAME,
  RENDER_SEATS_PAGE_TRACK_LABEL,
  RENDER_SEATS_ALERT_TRACK_LABEL,
  DISMISS_SEATS_ALERT_TRACK_LABEL,
} from 'ee/usage_quotas/seats/constants';
import { s__, __, sprintf, n__ } from '~/locale';
import FilterSortContainerRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
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
    GlToggle,
    GlSprintf,
    RemoveBillableMemberModal,
    SubscriptionSeatDetails,
    FilterSortContainerRoot,
    StatisticsCard,
    StatisticsSeatsCard,
    SubscriptionUpgradeInfoCard,
  },
  mixins: [Tracking.mixin()],
  data() {
    return {
      isDismissedSeatsAlert: getCookie(DISMISS_SEATS_ALERT_COOKIE_NAME) === 'true',
    };
  },
  computed: {
    ...mapState([
      'isLoading',
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
      'previewFreeUserCap',
    ]),
    ...mapGetters(['tableItems']),
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
        !this.hasLimitedPlanOrPreviewLimitedPlan
      );
    },
    seatsInUsePercentage() {
      if (this.totalSeatsAvailable == null) {
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
      if (this.hasLimitedPlanOrPreviewLimitedPlan) {
        return this.seatsInUse;
      }
      return this.hasNoSubscription ? this.total : this.seatsInUse;
    },
    seatsInUseText() {
      return this.hasLimitedPlanOrPreviewLimitedPlan
        ? this.$options.i18n.seatsAvailableText
        : this.$options.i18n.seatsInSubscriptionText;
    },
    seatsInUseTooltipText() {
      if (!this.hasLimitedFreePlan) {
        return null;
      }
      return sprintf(this.$options.i18n.seatsTooltipText, { number: this.maxFreeNamespaceSeats });
    },
    displayedTotalSeats() {
      return this.totalSeatsAvailable
        ? String(this.totalSeatsAvailable)
        : this.$options.i18n.unlimited;
    },
    fields() {
      return this.hasLimitedPlanOrPreviewLimitedPlan
        ? FIELDS_WITH_MEMBERSHIP_TOGGLE
        : STANDARD_FIELDS;
    },
    showUpgradeInfoCard() {
      if (!this.hasNoSubscription) {
        return false;
      }
      return this.hasLimitedPlanOrPreviewLimitedPlan;
    },
    hasLimitedPlanOrPreviewLimitedPlan() {
      return this.hasLimitedFreePlan || this.previewFreeUserCap;
    },
  },
  created() {
    this.fetchBillableMembersList();
    this.fetchGitlabSubscription();

    if (this.previewFreeUserCap) {
      this.track('render', { label: RENDER_SEATS_PAGE_TRACK_LABEL });
    }

    if (this.previewFreeUserCap && !this.isDismissedSeatsAlert) {
      this.track('render', { label: RENDER_SEATS_ALERT_TRACK_LABEL });
    }
  },
  methods: {
    ...mapActions([
      'fetchBillableMembersList',
      'fetchGitlabSubscription',
      'resetBillableMembers',
      'setBillableMemberToRemove',
      'changeMembershipState',
      'setSearchQuery',
      'setCurrentPage',
      'setSortOption',
    ]),
    applyFilter(searchTerms) {
      const searchQuery = searchTerms.reduce((terms, searchTerm) => {
        if (searchTerm.type !== 'filtered-search-term') {
          return '';
        }

        return `${terms} ${searchTerm.value.data}`;
      }, '');
      this.setSearchQuery(searchQuery.trim() || null);
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
    toggleProps(user) {
      const props = {
        disabled: false,
        title: '',
        value: user.membership_state === MEMBER_ACTIVE_STATE,
      };

      if (this.isLoading) {
        return { ...props, disabled: true };
      }

      if (user.id === gon.current_user_id) {
        return {
          ...props,
          disabled: true,
          title: this.$options.i18n.removeOwnSeatRestrictedText,
        };
      }

      if (user.is_last_owner) {
        return {
          ...props,
          disabled: true,
          title: this.$options.i18n.removeLastOwnerSeatRestrictedText,
        };
      }

      if (this.restrictActivatingUser(user)) {
        const title = this.isProjectOrGroupInvite(user)
          ? this.$options.i18n.activateGroupOrProjectMemberRestrictedText
          : this.$options.i18n.activateMemberRestrictedText;

        return { ...props, disabled: true, title };
      }

      return props;
    },
    restrictActivatingUser(user) {
      return (
        (this.hasReachedFreePlanLimit && user.membership_state === MEMBER_AWAITING_STATE) ||
        this.isProjectOrGroupInvite(user)
      );
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
    dismissSeatsAlert() {
      setCookie(DISMISS_SEATS_ALERT_COOKIE_NAME, 'true');
      this.isDismissedSeatsAlert = true;
      this.track('dismiss', { label: DISMISS_SEATS_ALERT_TRACK_LABEL });
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
    inASeatLabel: s__('Billings|In a seat'),
    seatsInUseLink: helpPagePath('subscriptions/gitlab_com/index', {
      anchor: 'how-seat-usage-is-determined',
    }),
    removeLastOwnerSeatRestrictedText: s__(
      'Billings|The last owner cannot be removed from a seat.',
    ),
    removeOwnSeatRestrictedText: s__(
      "Billings|You can't remove yourself from a seat, but you can leave the group.",
    ),
    activateMemberRestrictedText: s__(
      'Billings|To make this member active, you must first remove an existing active member, or toggle them to over limit.',
    ),
    seatsAlertTitle: s__('Billing|From October 19, 2022, free groups will be limited to 5 members'),
    seatsAlertBody: s__(
      "Billing|You can begin moving members in %{namespaceName} now. A member loses access to the group when you turn off %{strongStart}In a seat%{strongEnd}. If over 5 members have %{strongStart}In a seat%{strongEnd} enabled after October 19, 2022, we'll select the 5 members who maintain access. We'll first count members that have Owner and Maintainer roles, then the most recently active members until we reach 5 members. The remaining members will get a status of Over limit and lose access to the group.",
    ),
    unlimited: __('Unlimited'),
    activateGroupOrProjectMemberRestrictedText: s__(
      "Billings|You can't change the seat status of a user who was invited via a group or project.",
    ),
  },
  avatarSize: AVATAR_SIZE,

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
      @primaryAction="navigateToPendingMembersPage"
    >
      {{ pendingMembersAlertMessage }}
    </gl-alert>
    <div class="gl-bg-gray-10 gl-p-5">
      <gl-alert
        v-if="previewFreeUserCap && !isDismissedSeatsAlert"
        variant="info"
        class="gl-mb-5"
        data-testid="seats-alert-banner"
        :title="$options.i18n.seatsAlertTitle"
        @dismiss="dismissSeatsAlert"
      >
        <gl-sprintf :message="$options.i18n.seatsAlertBody">
          <template #namespaceName>{{ namespaceName }}</template>
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </gl-alert>

      <div class="gl-display-flex gl-sm-flex-direction-column">
        <statistics-card
          :help-link="$options.i18n.seatsInUseLink"
          :help-tooltip="seatsInUseTooltipText"
          :description="seatsInUseText"
          :percentage="seatsInUsePercentage"
          :usage-value="String(totalSeatsInUse)"
          :total-value="displayedTotalSeats"
          class="gl-w-full gl-md-w-half gl-md-mr-5"
        />

        <subscription-upgrade-info-card
          v-if="showUpgradeInfoCard"
          :max-namespace-seats="maxFreeNamespaceSeats"
          :explore-plans-path="explorePlansPath"
          class="gl-w-full gl-md-w-half gl-md-mt-0 gl-mt-5"
        />
        <statistics-seats-card
          v-else
          :seats-used="maxSeatsUsed"
          :seats-owed="seatsOwed"
          :purchase-button-link="addSeatsHref"
          class="gl-w-full gl-md-w-half gl-md-mt-0 gl-mt-5"
        />
      </div>
    </div>

    <div class="gl-bg-gray-10 gl-p-5 gl-display-flex">
      <filter-sort-container-root
        :namespace="namespaceId"
        :tokens="[] /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */"
        :search-input-placeholder="$options.i18n.filterUsersPlaceholder"
        :sort-options="$options.sortOptions"
        initial-sort-by="last_activity_on_desc"
        class="gl-flex-grow-1"
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
      class="seats-table"
      :items="tableItems"
      :fields="fields"
      :busy="isLoading"
      :show-empty="true"
      data-testid="table"
      :empty-text="emptyText"
    >
      <template #cell(user)="{ item, toggleDetails, detailsShowing }">
        <div class="gl-display-flex" :data-testid="`seat-cell-${item.user.id}`">
          <gl-button
            v-if="shouldShowDetails(item)"
            variant="link"
            class="gl-mr-2"
            :aria-label="s__('Billing|Toggle seat details')"
            data-testid="toggle-seat-usage-details"
            @click="toggleDetails"
          >
            <gl-icon
              :name="detailsShowing ? 'chevron-lg-down' : 'chevron-lg-right'"
              class="text-secondary-900"
            />
          </gl-button>

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
        <span>
          {{ data.item.user.last_activity_on ? data.item.user.last_activity_on : __('Never') }}
        </span>
      </template>

      <template #cell(membershipState)="{ item: { user } }">
        <gl-toggle
          v-gl-tooltip
          :label="$options.i18n.inASeatLabel"
          label-position="hidden"
          data-testid="seat-toggle"
          v-bind="toggleProps(user)"
          @change="changeMembershipState(user)"
        />
      </template>

      <template #cell(actions)="data">
        <gl-button
          v-gl-modal="$options.removeBillableMemberModalId"
          category="secondary"
          variant="danger"
          data-testid="remove-user"
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
