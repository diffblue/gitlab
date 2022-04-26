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
      return Api.project(id).then((res) => res.data);
    },
    fetchSuggestions(term) {
      return Api.projects(term, { membership: false }).then((res) => res.data);
    },
    getItemName({ name }) {
      return name;
    },
    getSuggestionValue({ id }) {
      return id.toString();
    },
    isValidIdentifier(id) {
      return isValidEntityId(id);
    },
    findActiveItem(suggestions, id) {
      const parsedId = parseInt(id, 10);
      return suggestions.find((p) => p.id === parsedId);
    },
  },
};
</script>

<template>
  <audit-filter-token v-bind="{ ...$attrs, ...$options.tokenMethods }" v-on="$listeners">
    <template #suggestion="{ item: project }">
      <p class="m-0">{{ project.name }}</p>
      <p class="m-0">{{ project.name_with_namespace }}</p>
    </template>
  </audit-filter-token>
</template>
