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
} from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import { helpPagePath } from '~/helpers/help_page_helper';
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
import FilterSortContainerRoot from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import StatisticsCard from 'ee/usage_quotas/components/statistics_card.vue';
import StatisticsSeatsCard from 'ee/usage_quotas/components/statistics_seats_card.vue';
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
    FilterSortContainerRoot,
    StatisticsCard,
    StatisticsSeatsCard,
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
      return this.pendingMembersCount > 0 && this.pendingMembersPagePath;
    },
    seatsInUsePercentage() {
      return Math.round((this.seatsInUse * 100) / this.seatsInSubscription);
    },
    totalSeatsInSubscription() {
      return this.hasNoSubscription ? '-' : String(this.seatsInSubscription);
    },
    totalSeatsInUse() {
      return this.hasNoSubscription ? String(this.total) : String(this.seatsInUse);
    },
  },
  created() {
    this.fetchBillableMembersList();
    this.fetchGitlabSubscription();
  },
  methods: {
    ...mapActions([
      'fetchBillableMembersList',
      'fetchGitlabSubscription',
      'resetBillableMembers',
      'setBillableMemberToRemove',
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
    isGroupInvite(item) {
      return item.user.membership_type === 'group_invite';
    },
    isProjectInvite(item) {
      return item.user.membership_type === 'project_invite';
    },
    shouldShowDetails(item) {
      return !this.isGroupInvite(item) && !this.isProjectInvite(item);
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
    seatsInUseText: s__('Billings|Seats in use / Seats in subscription'),
    seatsInUseLink: helpPagePath('subscription/gitlab_com/index', {
      anchor: 'how-seat-usage-is-determined',
    }),
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
      @primaryAction="navigateToPendingMembersPage"
    >
      {{ pendingMembersAlertMessage }}
    </gl-alert>
    <div class="gl-bg-gray-10 gl-display-flex gl-sm-flex-direction-column gl-p-5">
      <statistics-card
        :help-link="$options.i18n.seatsInUseLink"
        :description="$options.i18n.seatsInUseText"
        :percentage="seatsInUsePercentage"
        :usage-value="totalSeatsInUse"
        :total-value="totalSeatsInSubscription"
        class="gl-w-full gl-md-w-half gl-md-mr-5"
      />

      <statistics-seats-card
        :seats-used="maxSeatsUsed"
        :seats-owed="seatsOwed"
        :purchase-button-link="addSeatsHref"
        class="gl-w-full gl-md-w-half gl-md-mt-0 gl-mt-5"
      />
    </div>

    <div class="gl-bg-gray-10 gl-p-5 gl-display-flex">
      <filter-sort-container-root
        :namespace="namespaceId"
        :tokens="[]"
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
      :fields="$options.fields"
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
              :name="detailsShowing ? 'angle-down' : 'angle-right'"
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
                <gl-badge v-if="isGroupInvite(item)" size="sm" variant="muted">
                  {{ s__('Billing|Group invite') }}
                </gl-badge>
                <gl-badge v-if="isProjectInvite(item)" size="sm" variant="muted">
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
      :action-primary="{ text: __('Okay') }"
      static
    >
      <p>
        {{ $options.cannotRemoveModalText }}
      </p>
    </gl-modal>
  </section>
</template>
