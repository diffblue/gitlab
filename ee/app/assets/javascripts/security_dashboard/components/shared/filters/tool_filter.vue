<script>
import SimpleFilter from './simple_filter.vue';
import FilterBody from './filter_body.vue';

export default {
  components: { FilterBody },
  extends: SimpleFilter,
};
</script>

<template>
  <filter-body :name="filter.name" :selected-options="selectedOptionsOrAll" />
</template>
