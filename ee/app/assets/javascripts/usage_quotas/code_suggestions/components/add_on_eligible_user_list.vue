<script>
import {
  GlAvatarLabeled,
  GlAvatarLink,
  GlSkeletonLoader,
  GlTable,
  GlTooltipDirective,
  GlKeysetPagination,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { fetchPolicies } from '~/lib/graphql';
import { __, s__ } from '~/locale';
import { thWidthPercent } from '~/lib/utils/table_utility';
import getAddOnEligibleUsers from 'ee/usage_quotas/add_on/graphql/add_on_eligible_users.query.graphql';
import { ADD_ON_CODE_SUGGESTIONS } from 'ee/usage_quotas/code_suggestions/constants';
import {
  ADD_ON_ERROR_DICTIONARY,
  ADD_ON_ELIGIBLE_USERS_FETCH_ERROR_CODE,
} from 'ee/usage_quotas/error_constants';
import ErrorAlert from 'ee/vue_shared/components/error_alert/error_alert.vue';
import { scrollToElement } from '~/lib/utils/common_utils';
import CodeSuggestionsAddonAssignment from './code_suggestions_addon_assignment.vue';

const PER_PAGE = 20;

export default {
  name: 'AddOnEligibleUserList',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CodeSuggestionsAddonAssignment,
    ErrorAlert,
    GlAvatarLabeled,
    GlAvatarLink,
    GlKeysetPagination,
    GlSkeletonLoader,
    GlTable,
  },
  inject: ['fullPath'],
  props: {
    addOnPurchaseId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      addOnEligibleUsers: undefined,
      addOnEligibleUsersFetchError: undefined,
      addOnAssignmentError: undefined,
      sortOption: 'LAST_ACTIVITY_ON_DESC',
      pageInfo: undefined,
      cursor: { first: PER_PAGE },
    };
  },
  addOnErrorDictionary: ADD_ON_ERROR_DICTIONARY,
  avatarSize: 32,
  tableFields: [
    {
      key: 'user',
      label: __('User'),
      // eslint-disable-next-line @gitlab/require-i18n-strings
      thClass: `${thWidthPercent(30)} gl-pl-2!`,
      tdClass: 'gl-vertical-align-middle! gl-pl-2!',
    },
    {
      key: 'email',
      label: __('Email'),
      thClass: thWidthPercent(20),
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'codeSuggestionsAddon',
      label: s__('CodeSuggestions|Code Suggestions add-on'),
      thClass: thWidthPercent(25),
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'lastActivityTime',
      label: __('Last activity'),
      thClass: thWidthPercent(25),
      tdClass: 'gl-vertical-align-middle!',
    },
  ],
  apollo: {
    addOnEligibleUsers: {
      query: getAddOnEligibleUsers,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      nextFetchPolicy: fetchPolicies.CACHE_FIRST,
      variables() {
        return this.queryVariables;
      },
      update({ namespace }) {
        this.pageInfo = namespace?.addOnEligibleUsers?.pageInfo;
        return namespace?.addOnEligibleUsers?.edges?.map((edge) => ({
          ...edge.node,
          username: `@${edge.node.username}`,
          addOnAssignments: edge.node.addOnAssignments.nodes,
        }));
      },
      error(error) {
        this.addOnEligibleUsersFetchError = ADD_ON_ELIGIBLE_USERS_FETCH_ERROR_CODE;
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    queryVariables() {
      return {
        fullPath: this.fullPath,
        addOnType: ADD_ON_CODE_SUGGESTIONS,
        addOnPurchaseIds: [this.addOnPurchaseId],
        sort: this.sortOption,
        ...this.cursor,
      };
    },
    showPagination() {
      if (this.isLoaderShown || !this.pageInfo) {
        return false;
      }

      const { hasNextPage, hasPreviousPage } = this.pageInfo;

      return hasNextPage || hasPreviousPage;
    },
    emptyText() {
      return s__('Billing|No users to display.');
    },
    isLoaderShown() {
      return this.$apollo.queries.addOnEligibleUsers.loading;
    },
  },
  methods: {
    nextPage() {
      this.cursor = { first: PER_PAGE };
      this.cursor.nextPageCursor = this.pageInfo.endCursor;
    },
    prevPage() {
      this.cursor = { last: PER_PAGE };
      this.cursor.prevPageCursor = this.pageInfo.startCursor;
    },
    handleAddOnAssignmentError(errorCode) {
      this.addOnAssignmentError = errorCode;
      this.scrollToTop();
    },
    clearAddOnEligibleUsersFetchError() {
      this.addOnEligibleUsersFetchError = undefined;
    },
    clearAddOnAssignmentError() {
      this.addOnAssignmentError = undefined;
    },
    scrollToTop() {
      scrollToElement(this.$el);
    },
  },
};
</script>

<template>
  <section>
    <error-alert
      v-if="addOnEligibleUsersFetchError"
      data-testid="add-on-eligible-users-fetch-error"
      :error="addOnEligibleUsersFetchError"
      :error-dictionary="$options.addOnErrorDictionary"
      :dismissible="true"
      @dismiss="clearAddOnEligibleUsersFetchError"
    />

    <error-alert
      v-if="addOnAssignmentError"
      data-testid="add-on-assignment-error"
      :error="addOnAssignmentError"
      :error-dictionary="$options.addOnErrorDictionary"
      :dismissible="true"
      @dismiss="clearAddOnAssignmentError"
    />

    <gl-table
      :items="addOnEligibleUsers"
      :fields="$options.tableFields"
      :busy="isLoaderShown"
      :show-empty="true"
      :empty-text="emptyText"
      primary-key="id"
    >
      <template #table-busy>
        <div class="gl-ml-n4 gl-pt-3">
          <gl-skeleton-loader>
            <rect x="0" y="0" width="60" height="3" rx="1" />
            <rect x="126" y="0" width="60" height="3" rx="1" />
            <rect x="207" y="0" width="60" height="3" rx="1" />
            <rect x="338" y="0" width="60" height="3" rx="1" />
          </gl-skeleton-loader>
        </div>
      </template>
      <template #cell(user)="{ item }">
        <div class="gl-display-flex">
          <gl-avatar-link target="blank" :href="item.webUrl" :alt="item.name">
            <gl-avatar-labeled
              :src="item.avatarUrl"
              :size="$options.avatarSize"
              :label="item.name"
              :sub-label="item.username"
            />
          </gl-avatar-link>
        </div>
      </template>

      <template #cell(email)="{ item }">
        <div data-testid="email">
          <span v-if="item.publicEmail" class="gl-text-gray-900">{{ item.publicEmail }}</span>
          <span
            v-else
            v-gl-tooltip
            :title="s__('Billing|An email address is only visible for users with public emails.')"
            class="gl-font-style-italic"
          >
            {{ s__('Billing|Private') }}
          </span>
        </div>
      </template>

      <template #cell(codeSuggestionsAddon)="{ item }">
        <code-suggestions-addon-assignment
          :user-id="item.id"
          :add-on-assignments="item.addOnAssignments"
          :add-on-purchase-id="addOnPurchaseId"
          :add-on-eligible-users-query-variables="queryVariables"
          @handleAddOnAssignmentError="handleAddOnAssignmentError"
          @clearAddOnAssignmentError="clearAddOnAssignmentError"
        />
      </template>

      <template #cell(lastActivityTime)="data">
        <span data-testid="last_activity_on">
          {{ data.item.lastActivityOn ? data.item.lastActivityOn : __('Never') }}
        </span>
      </template>
    </gl-table>
    <div v-if="showPagination" class="gl-display-flex gl-justify-content-center gl-mt-5">
      <gl-keyset-pagination v-bind="pageInfo" @prev="prevPage" @next="nextPage" />
    </div>
  </section>
</template>
