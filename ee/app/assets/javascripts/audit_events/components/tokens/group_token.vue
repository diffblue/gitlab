<script>
import Api from '~/api';
import { isValidEntityId } from '../../token_utils';
import AuditFilterToken from './shared/audit_filter_token.vue';

export default {
  components: {
    AuditFilterToken,
  },
  inheritAttrs: false,
  tokenMethods: {
    fetchItem(id) {
      return Api.group(id);
    },
    fetchSuggestions(term) {
      return Api.groups(term);
    },
    getItemName(item) {
      return item.full_name;
    },
    getSuggestionValue({ id }) {
      return id.toString();
    },
    isValidIdentifier(id) {
      return isValidEntityId(id);
    },
    findActiveItem(suggestions, id) {
      const parsedId = parseInt(id, 10);
      return suggestions.find((g) => g.id === parsedId);
    },
  },
};
</script>

<template>
  <audit-filter-token v-bind="{ ...$attrs, ...$options.tokenMethods }" v-on="$listeners">
    <template #suggestion="{ item: group }">
      <p class="m-0">{{ group.full_name }}</p>
      <p class="m-0">{{ group.full_path }}</p>
    </template>
  </audit-filter-token>
</template>
