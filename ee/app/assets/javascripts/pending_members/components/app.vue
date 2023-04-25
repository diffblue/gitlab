<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import {
  GlAlert,
  GlAvatarLabeled,
  GlAvatarLink,
  GlBadge,
  GlButton,
  GlPagination,
  GlModal,
  GlModalDirective,
  GlLoadingIcon,
} from '@gitlab/ui';
import { n__, sprintf } from '~/locale';
import { AVATAR_SIZE } from 'ee/usage_quotas/seats/constants';
import {
  PENDING_MEMBERS_TITLE,
  AWAITING_MEMBER_SIGNUP_TEXT,
  LABEL_APPROVE,
  LABEL_APPROVE_ALL,
  LABEL_CONFIRM,
  LABEL_CONFIRM_APPROVE,
} from 'ee/pending_members/constants';

export default {
  name: 'PendingMembersApp',
  components: {
    GlAlert,
    GlAvatarLabeled,
    GlAvatarLink,
    GlBadge,
    GlButton,
    GlPagination,
    GlModal,
    GlLoadingIcon,
  },
  directives: {
    GlModalDirective,
  },
  i18n: {
    labelConfirmApprove: (count) =>
      n__('Approve a pending member', 'Approve %d pending members', count),
    labelConfirmApproveAll: (count) =>
      n__(
        'Approved members will use an additional seat in your subscription.',
        'Approved members will use an additional %d seats in your subscription.',
        count,
      ),
    labelConfirmApproveAllWithUserCapSet: (count) =>
      n__(
        'Approved members will use an additional seat in your subscription, which may override your user cap.',
        'Approved members will use an additional %d seats in your subscription, which may override your user cap.',
        count,
      ),
  },
  computed: {
    ...mapState([
      'isLoading',
      'alertMessage',
      'alertVariant',
      'page',
      'perPage',
      'total',
      'namespaceName',
      'namespaceId',
      'seatUsageExportPath',
      'pendingMembersPagePath',
      'pendingMembersCount',
      'search',
      'approveAllMembersLoading',
      'approveAllMembersDisabled',
      'userCapSet',
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
    approveAllPopoverTitle() {
      return this.$options.i18n.labelConfirmApprove(this.total);
    },
    approveAllPopoverBody() {
      if (this.userCapSet) {
        return this.$options.i18n.labelConfirmApproveAllWithUserCapSet(this.total);
      }
      return this.$options.i18n.labelConfirmApproveAll(this.total);
    },
  },
  created() {
    this.fetchPendingMembersList();
  },
  methods: {
    ...mapActions([
      'fetchPendingMembersList',
      'setCurrentPage',
      'approveMember',
      'approveAllMembers',
      'dismissAlert',
    ]),
    avatarLabel(member) {
      if (member.invited) {
        return member.email;
      }
      return member.name ?? '';
    },
    approveUserQuestion(member) {
      return sprintf(LABEL_CONFIRM_APPROVE, {
        user: member.name || member.email,
      });
    },
  },
  avatarSize: AVATAR_SIZE,
  AWAITING_MEMBER_SIGNUP_TEXT,
  LABEL_APPROVE,
  LABEL_APPROVE_ALL,
  LABEL_CONFIRM,
  PENDING_MEMBERS_TITLE,
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-justify-content-space-between">
      <h1 class="page-title gl-font-size-h-display">{{ $options.PENDING_MEMBERS_TITLE }}</h1>
      <div v-if="!isLoading" class="gl-align-self-center">
        <gl-button
          v-gl-modal-directive="`approve-all-confirmation-modal`"
          :loading="approveAllMembersLoading"
          :disabled="approveAllMembersDisabled"
          data-testid="approve-all-button"
        >
          {{ $options.LABEL_APPROVE_ALL }}
        </gl-button>
        <gl-modal
          :modal-id="`approve-all-confirmation-modal`"
          :title="approveAllPopoverTitle"
          no-fade
          data-testid="approve-all-modal"
          @primary="approveAllMembers"
        >
          <p>{{ approveAllPopoverBody }}</p>
        </gl-modal>
      </div>
    </div>

    <div v-if="isLoading" class="gl-text-center loading">
      <gl-loading-icon class="mt-5" size="lg" />
    </div>
    <template v-else>
      <div>
        <gl-alert v-if="alertMessage" :variant="alertVariant" @dismiss="dismissAlert">
          {{ alertMessage }}
        </gl-alert>
        <div
          v-for="item in tableItems"
          :key="item.id"
          class="gl-p-5 gl-border-0 gl-border-b-1! gl-border-gray-100 gl-border-solid gl-display-flex gl-justify-content-space-between"
          data-testid="pending-members-row"
          data-qa-selector="pending_members"
        >
          <gl-avatar-link target="blank" :href="item.web_url" :alt="item.name">
            <gl-avatar-labeled
              :src="item.avatar_url"
              :size="$options.avatarSize"
              :label="avatarLabel(item)"
            >
              <template #meta>
                <gl-badge v-if="item.invited && item.approved" size="sm" variant="muted">
                  {{ $options.AWAITING_MEMBER_SIGNUP_TEXT }}
                </gl-badge>
              </template>
            </gl-avatar-labeled>
          </gl-avatar-link>
          <gl-button
            v-gl-modal-directive="`approve-confirmation-modal-${item.id}`"
            :loading="item.loading"
            :disabled="item.approved"
            data-qa-selector="approve_member"
          >
            {{ $options.LABEL_APPROVE }}
          </gl-button>
          <gl-modal
            :modal-id="`approve-confirmation-modal-${item.id}`"
            :title="$options.LABEL_CONFIRM"
            data-qa-selector="approve_member_confirmation_modal"
            no-fade
            @primary="approveMember(item.id)"
          >
            <p>{{ approveUserQuestion(item) }}</p>
          </gl-modal>
        </div>
      </div>
    </template>

    <gl-pagination
      v-if="currentPage"
      v-model="currentPage"
      :per-page="perPage"
      :total-items="total"
      align="center"
      class="gl-mt-5"
    />
  </div>
</template>
