<script>
import Api from '~/api';
import { getUsers } from '~/rest_api';

import { parseUsername, displayUsername, isValidUsername } from '../../token_utils';
import AuditFilterToken from './shared/audit_filter_token.vue';

export default {
  components: {
    AuditFilterToken,
  },
  inheritAttrs: false,
  tokenMethods: {
    fetchItem(term) {
      const username = parseUsername(term);
      return getUsers('', { username, per_page: 1 }).then((res) => res.data[0]);
    },
    fetchSuggestions(term) {
      const { groupId, projectPath } = this.config;

      if (groupId) {
        return Api.groupMembers(groupId, { query: parseUsername(term) }).then((res) => res.data);
      }

      if (projectPath) {
        return Api.projectUsers(projectPath, parseUsername(term));
      }

      return {};
    },
    getItemName({ name }) {
      return name;
    },
    getSuggestionValue({ username }) {
      return displayUsername(username);
    },
    isValidIdentifier(username) {
      return isValidUsername(username);
    },
    findActiveItem(suggestions, username) {
      return suggestions.find((u) => u.username === parseUsername(username));
    },
  },
};
</script>

<template>
  <audit-filter-token v-bind="{ ...$attrs, ...$options.tokenMethods }" v-on="$listeners">
    <template #suggestion="{ item: user }">
      <p class="m-0">{{ user.name }}</p>
      <p class="m-0">@{{ user.username }}</p>
    </template>
  </audit-filter-token>
</template>
