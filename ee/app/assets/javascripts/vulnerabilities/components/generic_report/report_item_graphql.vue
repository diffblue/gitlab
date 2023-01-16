<script>
import { GRAPHQL_TYPENAME_TO_COMPONENT_MAP } from './types/constants';

export default {
  components: {
    // Register the components that are currently mapped to a GraphQL type, so they can be rendered dynamically
    ...GRAPHQL_TYPENAME_TO_COMPONENT_MAP,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <component :is="item.type" v-bind="item" data-testid="reportComponent" />
</template>
