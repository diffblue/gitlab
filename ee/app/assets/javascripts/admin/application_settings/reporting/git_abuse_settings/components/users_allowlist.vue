<script>
import { GlTokenSelector, GlAvatarLabeled } from '@gitlab/ui';

import getUsersByUsernames from '~/graphql_shared/queries/get_users_by_usernames.query.graphql';
import searchUsersQuery from '~/graphql_shared/queries/users_search_all.query.graphql';

import createFlash from '~/flash';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

import { SEARCH_USERS, LOAD_ERROR_MESSAGE, SEARCH_TERM_TOO_SHORT, NO_RESULTS } from '../constants';

const SEARCH_TERM_MINIMUM_LENGTH = 3;
const USERS_PER_PAGE = 20;

export default {
  name: 'UsersAllowlist',
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
  props: {
    excludedUsernames: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  apollo: {
    selectedUsers: {
      query() {
        return getUsersByUsernames;
      },
      variables() {
        return {
          usernames: this.excludedUsernames,
        };
      },
      update(data) {
        return data?.users?.nodes || [];
      },
      error(error) {
        createFlash({
          message: this.$options.i18n.LOAD_ERROR_MESSAGE,
          captureError: true,
          error,
        });
      },
      result() {
        this.firstFetch = false;
      },
      skip() {
        return !(this.firstFetch && this.excludedUsernames.length > 0);
      },
    },
    users: {
      query() {
        return searchUsersQuery;
      },
      variables() {
        return {
          search: this.search,
          first: USERS_PER_PAGE,
        };
      },
      update(data) {
        return data?.users?.nodes || [];
      },
      error(error) {
        createFlash({
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
  methods: {
    filterUsers(searchTerm) {
      this.search = searchTerm;

      if (this.isSearchTermTooShort) {
        this.users = [];
      }
    },
    emitUserAdded(user) {
      this.$emit('user-added', user.username);
    },
    emitUserRemoved(user) {
      this.$emit('user-removed', user.username);
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
      :text-input-attrs="{
        id: 'excluded-users',
      }"
      @text-input="filterUsers"
      @token-add="emitUserAdded"
      @token-remove="emitUserRemoved"
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
