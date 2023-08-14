<script>
import {
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
import * as Sentry from '@sentry/browser';
import dateFormat from '~/lib/dateformat';
import {
  FIELDS,
  AVATAR_SIZE,
  SORT_OPTIONS,
  REMOVE_BILLABLE_MEMBER_MODAL_ID,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_ID,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_TITLE,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT,
  FIELD_KEY_CODE_SUGGESTIONS_ADDON,
  ADD_ON_CODE_SUGGESTIONS,
  emailNotVisibleTooltipText,
  filterUsersPlaceholder,
} from 'ee/usage_quotas/seats/constants';
import {
  ADD_ON_ERROR_DICTIONARY,
  ADD_ON_PURCHASE_FETCH_ERROR_CODE,
} from 'ee/usage_quotas/error_constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, __ } from '~/locale';
import SearchAndSortBar from 'ee/usage_quotas/components/search_and_sort_bar/search_and_sort_bar.vue';
import getAddOnPurchaseQuery from 'ee/usage_quotas/graphql/queries/get_add_on_purchase_query.graphql';
import ErrorAlert from 'ee/vue_shared/components/error_alert/error_alert.vue';
import RemoveBillableMemberModal from './remove_billable_member_modal.vue';
import SubscriptionSeatDetails from './subscription_seat_details.vue';
import CodeSuggestionsAddonAssignment from './code_suggestions_addon_assignment.vue';

export default {
  name: 'SubscriptionUserList',
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CodeSuggestionsAddonAssignment,
    GlAvatarLabeled,
    GlAvatarLink,
    GlBadge,
    GlButton,
    GlModal,
    GlIcon,
    GlPagination,
    GlTable,
    RemoveBillableMemberModal,
    SearchAndSortBar,
    SubscriptionSeatDetails,
    ErrorAlert,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['fullPath'],
  data() {
    return {
      addOnPurchase: undefined,
      codeSuggestionsAddOnError: undefined,
    };
  },
  apollo: {
    addOnPurchase: {
      query: getAddOnPurchaseQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          addOnName: ADD_ON_CODE_SUGGESTIONS,
        };
      },
      update({ namespace }) {
        return {
          id: namespace?.addOnPurchase?.id,
          totalValue: namespace?.addOnPurchase?.purchasedQuantity ?? null,
        };
      },
      error(error) {
        this.codeSuggestionsAddOnError = ADD_ON_PURCHASE_FETCH_ERROR_CODE;
        Sentry.captureException(error);
      },
      skip() {
        return !this.shouldFetchCodeSuggestionsAddonDetails;
      },
    },
  },
  computed: {
    ...mapState([
      'hasError',
      'page',
      'perPage',
      'total',
      'namespaceId',
      'seatUsageExportPath',
      'billableMemberToRemove',
      'search',
      'hasNoSubscription',
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
    hasPurchasedCodeSuggestionsAddon() {
      return Boolean(this.addOnPurchase?.totalValue);
    },
    shouldFetchCodeSuggestionsAddonDetails() {
      return Boolean(this.glFeatures?.enableHamiltonInUsageQuotasUi) && !this.hasNoSubscription;
    },
    isLoaderShown() {
      return this.isLoading || this.hasError;
    },
    tableFields() {
      if (this.hasPurchasedCodeSuggestionsAddon) {
        return FIELDS;
      }

      return FIELDS.filter((field) => field.key !== FIELD_KEY_CODE_SUGGESTIONS_ADDON);
    },
  },
  methods: {
    ...mapActions([
      'setBillableMemberToRemove',
      'setCurrentPage',
      'setSearchQuery',
      'setSortOption',
    ]),
    formatLastLoginAt(lastLogin) {
      return lastLogin ? dateFormat(lastLogin, 'yyyy-mm-dd HH:MM:ss') : __('Never');
    },
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
    handleAddOnAssignmentError(error) {
      this.codeSuggestionsAddOnError = error;
    },
    hideCodeSuggestionsAddOnError() {
      this.codeSuggestionsAddOnError = undefined;
    },
  },
  i18n: {
    emailNotVisibleTooltipText,
    filterUsersPlaceholder,
  },
  avatarSize: AVATAR_SIZE,
  removeBillableMemberModalId: REMOVE_BILLABLE_MEMBER_MODAL_ID,
  cannotRemoveModalId: CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_ID,
  cannotRemoveModalTitle: CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_TITLE,
  cannotRemoveModalText: CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT,
  sortOptions: SORT_OPTIONS,
  addOnErrorDictionary: ADD_ON_ERROR_DICTIONARY,
};
</script>

<template>
  <section>
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

    <error-alert
      v-if="codeSuggestionsAddOnError"
      :error="codeSuggestionsAddOnError"
      :error-dictionary="$options.addOnErrorDictionary"
      :dismissible="true"
      @dismiss="hideCodeSuggestionsAddOnError"
    />

    <gl-table
      :items="tableItems"
      :fields="tableFields"
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
            :name="detailsShowing ? 'chevron-down' : 'chevron-right'"
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

      <template v-if="hasPurchasedCodeSuggestionsAddon" #cell(codeSuggestionsAddon)="{ item }">
        <code-suggestions-addon-assignment
          :user-id="item.user.id"
          :add-ons="item.user.add_ons"
          :add-on-purchase-id="addOnPurchase.id"
          @handleAddOnAssignmentError="handleAddOnAssignmentError"
        />
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
