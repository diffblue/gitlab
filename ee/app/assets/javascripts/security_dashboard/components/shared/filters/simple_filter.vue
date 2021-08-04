<script>
import { isEqual, xor } from 'lodash';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';

export default {
  components: { FilterBody, FilterItem },
  props: {
    filter: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      selectedOptions: undefined,
    };
  },
  computed: {
    options() {
      return this.filter.options;
    },
    selectedSet() {
      return new Set(this.selectedOptions);
    },
    isNoOptionsSelected() {
      return this.selectedOptions?.length <= 0;
    },
    selectedOptionsOrAll() {
      return this.selectedOptions?.length ? this.selectedOptions : [this.filter.allOption];
    },
    filterObject() {
      // This is passed to the vulnerability list's GraphQL query as a variable.
      return { [this.filter.id]: this.selectedOptions.map((x) => x.id) };
    },
    querystringIds() {
      const ids = this.$route?.query[this.filter.id] || [];
      const idArray = Array.isArray(ids) ? ids : [ids];

      return idArray.sort();
    },
    querystringOptions() {
      // If the querystring IDs includes the All option, return an empty array. We'll do this even
      // if there are other IDs because the special All option takes precedence.
      if (this.querystringIds.includes(this.filter.allOption.id)) {
        return [];
      }

      const options = this.options.filter((x) => this.querystringIds.includes(x.id));
      // If the querystring IDs didn't match any options, return the default options.
      if (!options.length) {
        return this.filter.defaultOptions;
      }

      return options;
    },
  },
  watch: {
    selectedOptions() {
      this.emitFilterChanged(this.filterObject);
    },
  },
  created() {
    this.processQuerystringIds();
    // When the user clicks the forward/back browser buttons, update the selected options.
    window.addEventListener('popstate', this.processQuerystringIds);
  },
  methods: {
    toggleOption(option) {
      // Toggle the option's existence in the array.
      this.selectedOptions = xor(this.selectedOptions, [option]);
      this.updateQuerystring();
    },
    deselectAllOptions() {
      this.selectedOptions = [];
      this.updateQuerystring();
    },
    updateQuerystring() {
      const options = this.selectedOptionsOrAll.map((x) => x.id);
      // To avoid a console error, don't update the querystring if it's the same as the current one.
      if (!this.$router || isEqual(this.querystringIds, options)) {
        return;
      }

      const query = { ...this.$route.query, [this.filter.id]: options };
      this.$router.push({ query });
    },
    isSelected(option) {
      return this.selectedSet.has(option);
    },
    processQuerystringIds() {
      this.selectedOptions = this.querystringOptions;
    },
    emitFilterChanged(data) {
      this.$emit('filter-changed', data);
    },
  },
};
</script>

<template>
  <filter-body :name="filter.name" :selected-options="selectedOptionsOrAll">
    <filter-item
      v-if="filter.allOption"
      :is-checked="isNoOptionsSelected"
      :text="filter.allOption.name"
      data-testid="allOption"
      @click="deselectAllOptions"
    />
    <filter-item
      v-for="option in options"
      :key="option.id"
      :is-checked="isSelected(option)"
      :text="option.name"
      :data-testid="`${filter.id}:${option.id}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
