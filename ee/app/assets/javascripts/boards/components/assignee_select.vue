<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownForm,
  GlDropdownDivider,
  GlDropdownItem,
  GlSearchBoxByType,
  GlLoadingIcon,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapActions, mapGetters } from 'vuex';
import searchGroupUsers from '~/graphql_shared/queries/group_users_search.query.graphql';
import searchProjectUsers from '~/graphql_shared/queries/users_search.query.graphql';
import { s__ } from '~/locale';
import { ASSIGNEES_DEBOUNCE_DELAY } from '~/sidebar/constants';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

export default {
  components: {
    UserAvatarImage,
    GlButton,
    GlDropdown,
    GlDropdownForm,
    GlDropdownDivider,
    GlDropdownItem,
    GlSearchBoxByType,
    GlLoadingIcon,
  },
  inject: ['fullPath'],
  props: {
    board: {
      type: Object,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    groupId: {
      type: Number,
      required: false,
      default: 0,
    },
    projectId: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      search: '',
      searchUsers: [],
      selected: this.board.assignee,
      isEditing: false,
      isDropdownShowing: false,
    };
  },
  apollo: {
    searchUsers: {
      query() {
        return this.isProjectBoard ? searchProjectUsers : searchGroupUsers;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          search: this.search,
          first: 20,
        };
      },
      skip() {
        return !this.isEditing;
      },
      update(data) {
        // TODO Remove null filter (BE fix required)
        // https://gitlab.com/gitlab-org/gitlab/-/issues/329750
        return data.workspace?.users?.nodes.filter((x) => x?.user).map(({ user }) => user) || [];
      },
      debounce: ASSIGNEES_DEBOUNCE_DELAY,
      error() {
        this.setError({ message: this.$options.i18n.errorSearchingUsers });
      },
    },
  },
  computed: {
    ...mapGetters(['isProjectBoard']),
    isLoading() {
      return this.$apollo.queries.searchUsers.loading;
    },
    isSearchEmpty() {
      return this.search === '' && !this.isLoading;
    },
    selectedIsEmpty() {
      return isEmpty(this.selected);
    },
    noUsersFound() {
      return !this.isSearchEmpty && this.users.length === 0;
    },
    users() {
      const filteredUsers = this.searchUsers.filter(
        (user) => user.name.includes(this.search) || user.username.includes(this.search),
      );

      // TODO this de-duplication is temporary (BE fix required)
      // https://gitlab.com/gitlab-org/gitlab/-/issues/327822
      return filteredUsers
        .concat(this.searchUsers)
        .reduce(
          (acc, current) => (acc.some((user) => current.id === user.id) ? acc : [...acc, current]),
          [],
        );
    },
  },
  methods: {
    ...mapActions(['setError']),
    selectAssignee(user) {
      this.selected = user;
      this.toggleEdit();
      this.$emit('set-assignee', user?.id || null);
    },
    toggleEdit() {
      if (!this.isEditing && !this.isDropdownShowing) {
        this.isEditing = true;
        this.showDropdown();
      } else {
        this.isEditing = false;
        this.isDropdownShowing = false;
      }
    },
    isSelected(user) {
      return this.selected?.username === user.username;
    },
    showDropdown() {
      this.$refs.editDropdown.show();
      this.isDropdownShowing = true;
    },
    setFocus() {
      this.$refs.search.focusInput();
    },
    hideDropdown() {
      this.isEditing = false;
    },
  },
  i18n: {
    label: s__('BoardScope|Assignee'),
    anyAssignee: s__('BoardScope|Any assignee'),
    selectAssignee: s__('BoardScope|Select assignee'),
    noMatchingResults: s__('BoardScope|No matching results'),
    errorSearchingUsers: s__(
      'BoardScope|An error occurred while searching for users, please try again.',
    ),
    edit: s__('BoardScope|Edit'),
  },
};
</script>

<template>
  <div class="block assignee">
    <div class="title gl-mb-3">
      {{ $options.i18n.label }}
      <gl-button
        v-if="canEdit"
        variant="link"
        class="edit-link float-right gl-text-gray-900!"
        @click="toggleEdit"
      >
        {{ $options.i18n.edit }}
      </gl-button>
    </div>
    <div v-if="!isEditing" data-testid="selected-assignee">
      <div v-if="!selectedIsEmpty" class="gl-display-flex gl-align-items-center">
        <user-avatar-image :img-src="selected.avatarUrl || selected.avatar_url" :size="32" />
        <div>
          <div class="gl-font-weight-bold">{{ selected.name }}</div>
          <div>@{{ selected.username }}</div>
        </div>
      </div>
      <div v-else class="gl-text-gray-500">{{ $options.i18n.anyAssignee }}</div>
    </div>

    <gl-dropdown
      v-show="isEditing"
      ref="editDropdown"
      :text="$options.i18n.selectAssignee"
      lazy
      menu-class="gl-w-full!"
      class="gl-w-full"
      @shown="setFocus"
      @hide="hideDropdown"
    >
      <template #header>
        <gl-search-box-by-type ref="search" v-model.trim="search" class="js-dropdown-input-field" />
      </template>
      <gl-dropdown-form class="gl-relative gl-min-h-7">
        <gl-loading-icon
          v-if="isLoading"
          size="md"
          class="gl-absolute gl-left-0 gl-top-0 gl-right-0"
        />
        <template v-else>
          <gl-dropdown-item
            v-if="isSearchEmpty"
            :is-checked="selectedIsEmpty"
            :is-check-centered="true"
            @click="selectAssignee(null)"
          >
            <span :class="selectedIsEmpty ? 'gl-pl-0' : 'gl-pl-6'" class="gl-font-weight-bold">
              {{ $options.i18n.anyAssignee }}
            </span>
          </gl-dropdown-item>
          <gl-dropdown-divider />
          <gl-dropdown-item
            v-for="user in users"
            :key="user.id"
            :is-checked="isSelected(user)"
            :is-check-centered="true"
            :is-check-item="true"
            :avatar-url="user.avatar_url || user.avatarUrl"
            :secondary-text="user.username"
            data-testid="unselected-user"
            @click="selectAssignee(user)"
          >
            {{ user.name }}
          </gl-dropdown-item>
          <gl-dropdown-item v-if="noUsersFound" class="gl-pl-6!">
            {{ $options.i18n.noMatchingResults }}
          </gl-dropdown-item>
        </template>
      </gl-dropdown-form>
      <template #footer>
        <slot name="footer"></slot>
      </template>
    </gl-dropdown>
  </div>
</template>
