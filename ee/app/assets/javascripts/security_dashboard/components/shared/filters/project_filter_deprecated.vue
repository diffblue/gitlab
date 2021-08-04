<script>
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';
import SimpleFilter from './simple_filter.vue';

const SHOW_SEARCH_BOX_THRESHOLD = 20;

export default {
  components: { FilterBody, FilterItem },
  extends: SimpleFilter,
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    filteredOptions() {
      return this.options.filter((option) =>
        option.name.toLowerCase().includes(this.searchTerm.toLowerCase()),
      );
    },
    showSearchBox() {
      return this.options.length >= SHOW_SEARCH_BOX_THRESHOLD;
    },
  },
};
</script>

<template>
  <filter-body
    v-model.trim="searchTerm"
    :name="filter.name"
    :selected-options="selectedOptionsOrAll"
    :show-search-box="showSearchBox"
  >
    <filter-item
      v-if="filter.allOption && !searchTerm.length"
      :is-checked="isNoOptionsSelected"
      :text="filter.allOption.name"
      data-testid="allOption"
      @click="deselectAllOptions"
    />
    <filter-item
      v-for="option in filteredOptions"
      :key="option.id"
      :is-checked="isSelected(option)"
      :text="option.name"
      :data-testid="`${filter.id}:${option.id}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
