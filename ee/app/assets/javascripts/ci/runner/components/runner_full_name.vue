<script>
import { getIdFromGraphQLId, getTypeFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';

export default {
  props: {
    runner: {
      type: Object,
      default: null,
      required: false,
      validator(val) {
        return getTypeFromGraphQLId(val.id) === TYPENAME_CI_RUNNER;
      },
    },
  },
  computed: {
    text() {
      if (!this.runner) {
        return '';
      }

      const { id, shortSha, description } = this.runner;

      let text = `#${getIdFromGraphQLId(id)}`;
      if (shortSha) {
        text += ` (${shortSha})`;
      }
      if (description) {
        text += ` - ${description}`;
      }
      return text;
    },
  },
};
</script>
<template>
  <span>{{ text }}</span>
</template>
