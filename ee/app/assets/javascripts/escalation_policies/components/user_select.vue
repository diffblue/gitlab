<script>
import { GlTokenSelector, GlAvatar, GlAvatarLabeled, GlToken } from '@gitlab/ui';
import searchProjectMembersQuery from '~/graphql_shared/queries/project_user_members_search.query.graphql';
import { s__, __ } from '~/locale';

export default {
  components: {
    GlTokenSelector,
    GlAvatar,
    GlAvatarLabeled,
    GlToken,
  },
  inject: ['projectPath'],

  i18n: {
    placeholder: s__('EscalationPolicies|Search for user'),
    noResults: __('No matching results'),
  },
  props: {
    selectedUserName: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    users: {
      query: searchProjectMembersQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          search: this.search,
        };
      },
      update({ project: { projectMembers: { nodes = [] } = {} } = {} } = {}) {
        return nodes.filter((x) => x?.user).map(({ user }) => ({ ...user }));
      },
      error(error) {
        this.error = error;
      },
      result() {
        this.setSelectedUser();
      },
      debounce: 250,
    },
  },
  data() {
    return {
      users: [],
      selectedUsers: [],
      search: '',
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.users.loading;
    },
    placeholderText() {
      return this.selectedUsers.length ? '' : this.$options.i18n.placeholder;
    },
    user() {
      return this.selectedUsers[0];
    },
  },
  methods: {
    filterUsers(searchTerm) {
      this.search = searchTerm;
    },
    emitUserUpdate() {
      this.$emit('select-user', this.user?.username);
    },
    clearSelectedUsers() {
      this.selectedUsers = [];
      this.emitUserUpdate();
    },
    setSelectedUser() {
      const selectedUser = this.users.find(({ username }) => username === this.selectedUserName);
      if (selectedUser) {
        this.selectedUsers.push(selectedUser);
      }
    },
  },
};
</script>
<template>
  <div
    v-if="selectedUsers.length"
    class="gl-inset-border-1-gray-400 gl-px-3 gl-py-2 gl-rounded-base rule-control"
  >
    <gl-token @close="clearSelectedUsers">
      <gl-avatar :src="user.avatarUrl" :size="16" />
      {{ user.name }}
    </gl-token>
  </div>

  <gl-token-selector
    v-else
    ref="tokenSelector"
    v-model="selectedUsers"
    :dropdown-items="users"
    :loading="loading"
    :placeholder="placeholderText"
    container-class="rule-control"
    @text-input="filterUsers"
    @token-add="emitUserUpdate"
  >
    <template #dropdown-item-content="{ dropdownItem }">
      <gl-avatar-labeled
        :src="dropdownItem.avatarUrl"
        :size="32"
        :label="dropdownItem.name"
        :sub-label="dropdownItem.username"
      />
    </template>
  </gl-token-selector>
</template>
