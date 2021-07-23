<script>
import {
  GlAvatarLabeled,
  GlAvatarLink,
  GlBadge,
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlModal,
  GlModalDirective,
  GlIcon,
  GlPagination,
  GlSearchBoxByType,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import { parseInt, debounce } from 'lodash';
import { mapActions, mapState, mapGetters } from 'vuex';
import {
  FIELDS,
  AVATAR_SIZE,
  SEARCH_DEBOUNCE_MS,
  REMOVE_BILLABLE_MEMBER_MODAL_ID,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_ID,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_TITLE,
  CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT,
} from 'ee/billings/seat_usage/constants';
import { s__ } from '~/locale';
import RemoveBillableMemberModal from './remove_billable_member_modal.vue';
import SubscriptionSeatDetails from './subscription_seat_details.vue';

export default {
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlAvatarLabeled,
    GlAvatarLink,
    GlBadge,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlModal,
    GlIcon,
    GlPagination,
    GlSearchBoxByType,
    GlTable,
    RemoveBillableMemberModal,
    SubscriptionSeatDetails,
  },
  data() {
    return {
      searchQuery: '',
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
      'billableMemberToRemove',
    ]),
    ...mapGetters(['tableItems']),
    currentPage: {
      get() {
        return parseInt(this.page, 10);
      },
      set(val) {
        this.fetchBillableMembersList({ page: val, search: this.searchQuery });
      },
    },
    perPageFormatted() {
      return parseInt(this.perPage, 10);
    },
    totalFormatted() {
      return parseInt(this.total, 10);
    },
    emptyText() {
      if (this.searchQuery?.length < 3) {
        return s__('Billing|Enter at least three characters to search.');
      }
      return s__('Billing|No users to display.');
    },
  },
  watch: {
    searchQuery() {
      this.executeQuery();
    },
  },
  created() {
    // This method is defined here instead of in `methods`
    // because we need to access the .cancel() method
    // lodash attaches to the function, which is
    // made inaccessible by Vue. More info:
    // https://stackoverflow.com/a/52988020/1063392
    this.debouncedSearch = debounce(function search() {
      this.fetchBillableMembersList({ search: this.searchQuery });
    }, SEARCH_DEBOUNCE_MS);

    this.fetchBillableMembersList();
  },
  methods: {
    ...mapActions([
      'fetchBillableMembersList',
      'resetBillableMembers',
      'setBillableMemberToRemove',
    ]),
    onSearchEnter() {
      this.debouncedSearch.cancel();
      this.executeQuery();
    },
    executeQuery() {
      const queryLength = this.searchQuery?.length;
      const MIN_SEARCH_LENGTH = 3;

      if (queryLength === 0 || queryLength >= MIN_SEARCH_LENGTH) {
        this.debouncedSearch();
      } else if (queryLength < MIN_SEARCH_LENGTH) {
        this.resetBillableMembers();
      }
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
  },
  i18n: {
    emailNotVisibleTooltipText: s__(
      'Billing|An email address is only visible for users with public emails.',
    ),
  },
  avatarSize: AVATAR_SIZE,
  fields: FIELDS,
  removeBillableMemberModalId: REMOVE_BILLABLE_MEMBER_MODAL_ID,
  cannotRemoveModalId: CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_ID,
  cannotRemoveModalTitle: CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_TITLE,
  cannotRemoveModalText: CANNOT_REMOVE_BILLABLE_MEMBER_MODAL_CONTENT,
};
</script>

<template>
  <section>
    <div
      class="gl-bg-gray-10 gl-p-6 gl-md-display-flex gl-justify-content-space-between gl-align-items-center"
    >
      <div data-testid="heading-info">
        <h4
          data-testid="heading-info-text"
          class="gl-font-base gl-display-inline-block gl-font-weight-normal"
        >
          {{ s__('Billing|Users occupying seats in') }}
          <span class="gl-font-weight-bold">{{ namespaceName }} {{ s__('Billing|Group') }}</span>
        </h4>
        <gl-badge>{{ total }}</gl-badge>
      </div>

      <gl-search-box-by-type
        v-model.trim="searchQuery"
        :placeholder="s__('Billing|Type to search')"
        @keydown.enter.prevent="onSearchEnter"
      />
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
        <div class="gl-display-flex">
          <gl-button
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
        <gl-dropdown icon="ellipsis_h" right data-testid="user-actions">
          <gl-dropdown-item
            v-gl-modal="$options.removeBillableMemberModalId"
            data-testid="remove-user"
            @click="displayRemoveMemberModal(data.item.user)"
          >
            {{ __('Remove user') }}
          </gl-dropdown-item>
        </gl-dropdown>
      </template>

      <template #row-details="{ item }">
        <subscription-seat-details :seat-member-id="item.user.id" />
      </template>
    </gl-table>

    <gl-pagination
      v-if="currentPage"
      v-model="currentPage"
      :per-page="perPageFormatted"
      :total-items="totalFormatted"
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
