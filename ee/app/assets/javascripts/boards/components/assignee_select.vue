<script>
import { GlButton } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapActions } from 'vuex';
import searchGroupUsers from '~/graphql_shared/queries/group_users_search.query.graphql';
import searchProjectUsers from '~/graphql_shared/queries/users_search.query.graphql';
import { s__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import DropdownWidget from '~/vue_shared/components/dropdown/dropdown_widget/dropdown_widget.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';

import { AssigneesPreset, ANY_ASSIGNEE } from '../constants';

export default {
  AssigneesPreset,
  components: {
    UserAvatarImage,
    DropdownWidget,
    GlButton,
  },
  inject: ['fullPath', 'isProjectBoard'],
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
      debounce: DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
      error() {
        this.setError({ message: this.$options.i18n.errorSearchingUsers });
      },
    },
  },
  computed: {
    anyAssignee() {
      return this.selected.name === ANY_ASSIGNEE.name;
    },
    isLoading() {
      return this.$apollo.queries.searchUsers.loading;
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
  created() {
    if (isEmpty(this.board.assignee)) {
      this.selected = ANY_ASSIGNEE;
    }
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
    showDropdown() {
      this.$refs.editDropdown.showDropdown();
      this.isDropdownShowing = true;
    },
    hideDropdown() {
      this.isEditing = false;
    },
    setSearch(search) {
      this.search = search;
    },
  },
  i18n: {
    label: s__('BoardScope|Assignee'),
    anyAssignee: s__('BoardScope|Any assignee'),
    selectAssignee: s__('BoardScope|Select assignee'),
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
        category="tertiary"
        size="small"
        class="edit-link float-right"
        @click="toggleEdit"
      >
        {{ $options.i18n.edit }}
      </gl-button>
    </div>
    <div v-if="!isEditing" data-testid="selected-assignee">
      <div v-if="!anyAssignee" class="gl-display-flex gl-align-items-center">
        <user-avatar-image :img-src="selected.avatarUrl || selected.avatar_url" :size="32" />
        <div>
          <div class="gl-font-weight-bold">{{ selected.name }}</div>
          <div>@{{ selected.username }}</div>
        </div>
      </div>
      <div v-else class="gl-text-gray-500">{{ $options.i18n.anyAssignee }}</div>
    </div>

    <dropdown-widget
      v-show="isEditing"
      ref="editDropdown"
      :select-text="$options.i18n.selectAssignee"
      :preset-options="$options.AssigneesPreset"
      :options="users"
      :is-loading="isLoading"
      :selected="selected"
      :search-term="search"
      @hide="hideDropdown"
      @set-option="selectAssignee"
      @set-search="setSearch"
    >
      <template #preset-item="{ item }">
        {{ item.name }}
      </template>
      <template #item="{ item }">
        {{ item.name }}
      </template>
    </dropdown-widget>
  </div>
</template>
