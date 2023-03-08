<script>
import { GlTokenSelector, GlAvatarLabeled } from '@gitlab/ui';

import getUsersByUserIdsOrUsernames from 'ee/graphql_shared/queries/get_users_by_user_ids_or_usernames.query.graphql';
import searchUsersQuery from '~/graphql_shared/queries/users_search_all.query.graphql';
import searchGroupUsers from '~/graphql_shared/queries/group_users_search.query.graphql';
import { getIdFromGraphQLId, convertToGraphQLIds } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';

import { createAlert } from '~/alert';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

import { SEARCH_USERS, LOAD_ERROR_MESSAGE, SEARCH_TERM_TOO_SHORT, NO_RESULTS } from '../constants';

const SEARCH_TERM_MINIMUM_LENGTH = 3;
const USERS_PER_PAGE = 20;

export default {
  name: 'UsersSelect',
  components: {
    GlTokenSelector,
    GlAvatarLabeled,
  },
  i18n: {
    SEARCH_USERS,
    LOAD_ERROR_MESSAGE,
    SEARCH_TERM_TOO_SHORT,
    NO_RESULTS,
  },
  inject: { groupFullPath: { default: '' } },
  props: {
    inputId: {
      type: String,
      required: true,
    },
    selectByUsername: {
      type: Boolean,
      required: false,
      default: true,
    },
    selected: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  apollo: {
    selectedUsers: {
      query() {
        return getUsersByUserIdsOrUsernames;
      },
      variables() {
        return this.selectByUsername
          ? { usernames: this.selected }
          : { user_ids: convertToGraphQLIds(TYPENAME_USER, this.selected) };
      },
      update(data) {
        return data?.users?.nodes || [];
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.LOAD_ERROR_MESSAGE,
          captureError: true,
          error,
        });
      },
      result() {
        this.firstFetch = false;
      },
      skip() {
        return !(this.firstFetch && this.selected.length > 0);
      },
    },
    users: {
      query() {
        return this.groupFullPath ? searchGroupUsers : searchUsersQuery;
      },
      variables() {
        return {
          search: this.search,
          first: USERS_PER_PAGE,
          fullPath: this.groupFullPath,
        };
      },
      update(data) {
        const users = this.groupFullPath
          ? data?.workspace?.users?.nodes?.map((groupMember) => groupMember.user)
          : data?.users?.nodes;

        return users || [];
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.LOAD_ERROR_MESSAGE,
          captureError: true,
          error,
        });
      },
      skip() {
        return this.search.length !== 0 && this.isSearchTermTooShort;
      },
      debounce: DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
    },
  },
  data() {
    return {
      users: [],
      selectedUsers: [],
      search: '',
      firstFetch: true,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.users.loading;
    },
    isSearchTermTooShort() {
      return this.search.length < SEARCH_TERM_MINIMUM_LENGTH;
    },
    emptyResultsMessage() {
      return this.isSearchTermTooShort
        ? this.$options.i18n.SEARCH_TERM_TOO_SHORT
        : this.$options.i18n.NO_RESULTS;
    },
    placeholderText() {
      return this.selectedUsers.length ? '' : this.$options.i18n.SEARCH_USERS;
    },
  },
  watch: {
    selectedUsers(newVal) {
      this.$emit('selection-changed', newVal.map(this.userProperty));
    },
  },
  methods: {
    filterUsers(searchTerm) {
      this.search = searchTerm;

      if (this.isSearchTermTooShort) {
        this.users = [];
      }
    },
    userProperty(user) {
      return this.selectByUsername ? user.username : getIdFromGraphQLId(user.id);
    },
  },
};
</script>
<template>
  <div>
    <gl-token-selector
      ref="tokenSelector"
      v-model="selectedUsers"
      :dropdown-items="users"
      :loading="isLoading"
      :placeholder="placeholderText"
      :text-input-attrs="{ id: inputId }"
      @text-input="filterUsers"
    >
      <template #dropdown-item-content="{ dropdownItem }">
        <gl-avatar-labeled
          :src="dropdownItem.avatarUrl"
          :size="32"
          :label="dropdownItem.name"
          :sub-label="dropdownItem.username"
        />
      </template>
      <template #no-results-content>
        {{ emptyResultsMessage }}
      </template>
    </gl-token-selector>
  </div>
</template>
