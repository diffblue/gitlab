<script>
export default {
  components: {
    ReportItem: () => import('../report_item_graphql.vue'),
  },
  inheritAttrs: false,
  props: {
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
};
</script>

<template>
  <div v-if="items.length > 0" class="gl-display-table">
    <ul class="generic-report-named-list">
      <li
        v-for="{ fieldName, name, value } in items"
        :key="fieldName"
        class="generic-report-named-list-item"
        data-testid="listItem"
      >
        <strong class="generic-report-named-list-label">{{ name }}</strong>
        <span class="generic-report-named-list-value">
          <report-item :item="value" :data-testid="`listValue${fieldName}`" />
        </span>
      </li>
    </ul>
  </div>
</template>
