<script>
import { GlAvatarLabeled, GlListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import searchProjectMembers from '~/graphql_shared/queries/project_user_members_search.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { USER_TYPE } from './lib/actions';

const createUserObject = (user) => ({
  ...user,
  text: user.name,
  username: `@${user.username}`,
  value: user.value || user.id,
});

export default {
  components: {
    GlAvatarLabeled,
    GlListbox,
  },
  inject: ['namespacePath'],
  props: {
    existingApprovers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  apollo: {
    users: {
      query: searchProjectMembers,
      variables() {
        return {
          fullPath: this.namespacePath,
          search: this.search,
        };
      },
      update(data) {
        return (data?.project?.projectMembers?.nodes || []).map(({ user }) =>
          createUserObject(user),
        );
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
  <gl-listbox
    :items="users"
    searchable
    is-check-centered
    multiple
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
  </gl-listbox>
</template>
