<script>
const GRAPHQL_TYPENAME_TO_COMPONENT_MAP = {
  VulnerabilityDetailUrl: () => import('./types/url.vue'),
  VulnerabilityDetailDiff: () => import('./types/diff.vue'),
  VulnerabilityDetailCode: () => import('./types/code.vue'),
  VulnerabilityDetailFileLocation: () => import('./types/file_location.vue'),
  VulnerabilityDetailModuleLocation: () => import('./types/module_location.vue'),
  VulnerabilityDetailCommit: () => import('./types/commit.vue'),
  VulnerabilityDetailValue: () => import('./types/value.vue'),
  VulnerabilityDetailText: () => import('./types/value.vue'),
  VulnerabilityDetailMarkdown: () => import('./types/markdown.vue'),
  VulnerabilityDetailBoolean: () => import('./types/value.vue'),
  VulnerabilityDetailInt: () => import('./types/value.vue'),
  VulnerabilityDetailList: () => import('./types/list_graphql.vue'),
  VulnerabilityDetailTable: () => import('./types/table_graphql.vue'),
};

export const GRAPHQL_TYPENAMES = Object.keys(GRAPHQL_TYPENAME_TO_COMPONENT_MAP);

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
