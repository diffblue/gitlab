<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlAvatarLabeled, GlAvatarLink, GlBadge, GlPagination, GlLoadingIcon } from '@gitlab/ui';
import { AVATAR_SIZE } from 'ee/seat_usage/constants';
import { AWAITING_MEMBER_SIGNUP_TEXT } from 'ee/pending_members/constants';

export default {
  name: 'PendingMembersApp',
  components: { GlAvatarLabeled, GlAvatarLink, GlBadge, GlPagination, GlLoadingIcon },
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
      'search',
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
  },
  created() {
    this.fetchPendingMembersList();
  },
  AWAITING_MEMBER_SIGNUP_TEXT,
  methods: {
    ...mapActions(['fetchPendingMembersList', 'setCurrentPage']),
    avatarLabel(member) {
      if (member.invited) {
        return member.email;
      }
      return member.name ?? '';
    },
  },
  avatarSize: AVATAR_SIZE,
};
</script>
<template>
  <div>
    <div v-if="isLoading" class="gl-text-center loading">
      <gl-loading-icon class="mt-5" size="lg" />
    </div>
    <template v-else>
      <div
        v-for="item in tableItems"
        :key="item.id"
        class="gl-p-5 gl-border-0 gl-border-b-1! gl-border-gray-100 gl-border-solid"
        data-testid="pending-members-row"
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
