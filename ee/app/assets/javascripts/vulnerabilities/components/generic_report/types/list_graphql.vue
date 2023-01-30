<script>
export default {
  components: {
    ReportItem: () => import('../report_item_graphql.vue'),
  },
  inheritAttrs: false,
  props: {
    items: {
      type: Array,
      required: true,
    },
  },
  computed: {
    hasNestedListItems() {
      return this.items.some(this.isOfTypeList);
    },
  },
  methods: {
    isOfTypeList(item) {
      return item.type === 'VulnerabilityDetailList';
    },
  },
};
</script>
<template>
  <ul
    data-testid="generic-report-type-list"
    class="generic-report-list"
    :class="{ 'generic-report-list-nested': hasNestedListItems }"
  >
    <li
      v-for="item in items"
      :key="item.name"
      data-testid="generic-report-type-list-item"
      :class="{ 'gl-list-style-none!': isOfTypeList(item) }"
    >
      <report-item :item="item" data-testid="report-item" />
    </li>
  </ul>
</template>
