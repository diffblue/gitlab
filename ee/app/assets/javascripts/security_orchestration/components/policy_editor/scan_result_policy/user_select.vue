<script>
import { GlAvatarLabeled, GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import searchProjectMembers from '~/graphql_shared/queries/project_user_members_search.query.graphql';
import searchGroupMembers from '~/graphql_shared/queries/group_users_search.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { NAMESPACE_TYPES, USER_TYPE } from 'ee/security_orchestration/constants';

const createUserObject = (user) => ({
  ...user,
  text: user.name,
  username: `@${user.username}`,
  value: user.value || user.id,
});

export default {
  components: {
    GlAvatarLabeled,
    GlCollapsibleListbox,
  },
  inject: ['namespacePath', 'namespaceType'],
  props: {
    existingApprovers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  apollo: {
    users: {
      query() {
        return this.namespaceType === NAMESPACE_TYPES.PROJECT
          ? searchProjectMembers
          : searchGroupMembers;
      },
      variables() {
        return {
          fullPath: this.namespacePath,
          search: this.search,
        };
      },
      update(data) {
        const nodes =
          this.namespaceType === NAMESPACE_TYPES.PROJECT
            ? data?.project?.projectMembers?.nodes
            : data?.workspace?.users?.nodes;

        return (nodes || []).map(({ user }) => createUserObject(user));
      },
      debounce: DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
    },
  },
  data() {
    return {
      selectedUsers: this.existingApprovers.map((a) => createUserObject(a)),
      search: '',
    };
  },
  computed: {
    selectedUsersValues() {
      return this.selectedUsers.map((u) => u.value);
    },
    toggleText() {
      return this.selectedUsers.length
        ? this.selectedUsers.map((u) => u.text).join(', ')
        : s__('SecurityOrchestration|Select users');
    },
  },
  methods: {
    handleSelectedUser(usersIds) {
      const updatedSelectedUsers = this.createSelectedUsers(usersIds);

      this.selectedUsers = updatedSelectedUsers;
      this.$emit('updateSelectedApprovers', updatedSelectedUsers);
    },
    createSelectedUsers(usersIds) {
      let updatedSelectedUsers = [...this.selectedUsers];

      const isAddingUser = this.selectedUsers.length < usersIds.length;
      if (isAddingUser) {
        const newUser = this.users.find((u) => u.value === usersIds[usersIds.length - 1]);
        updatedSelectedUsers.push({
          ...newUser,
          type: USER_TYPE,
          id: getIdFromGraphQLId(newUser.value),
        });
      } else {
        updatedSelectedUsers = this.selectedUsers.filter((selectedUser) =>
          usersIds.includes(selectedUser.value),
        );
      }

      return updatedSelectedUsers;
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :items="users"
    searchable
    is-check-centered
    multiple
    toggle-class="gl-max-w-26"
    :searching="$apollo.loading"
    :selected="selectedUsersValues"
    :toggle-text="toggleText"
    @search="search = $event"
    @select="handleSelectedUser"
  >
    <template #list-item="{ item }">
      <gl-avatar-labeled
        shape="circle"
        :size="32"
        :src="item.avatarUrl"
        :label="item.text"
        :sub-label="item.username"
      />
    </template>
  </gl-collapsible-listbox>
</template>
