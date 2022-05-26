<script>
import { GlDropdownDivider } from '@gitlab/ui';
import { xor, remove } from 'lodash';
import { activityOptions } from 'ee/security_dashboard/helpers';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';
import SimpleFilter from './simple_filter.vue';

const { NO_ACTIVITY, WITH_ISSUES, NO_LONGER_DETECTED } = activityOptions;

export default {
  components: { FilterBody, FilterItem, GlDropdownDivider },
  extends: SimpleFilter,
  computed: {
    filterObject() {
      // This is the object used to update the GraphQL query.
      if (this.isNoOptionsSelected) {
        return {
          hasIssues: undefined,
          hasResolution: undefined,
        };
      }

      return {
        hasIssues: this.isSelected(WITH_ISSUES),
        hasResolution: this.isSelected(NO_LONGER_DETECTED),
      };
    },
    multiselectOptions() {
      return [WITH_ISSUES, NO_LONGER_DETECTED];
    },
  },
  methods: {
    toggleOption(option) {
      if (option === NO_ACTIVITY) {
        this.selectedOptions = this.selectedSet.has(NO_ACTIVITY) ? [] : [NO_ACTIVITY];
      } else {
        remove(this.selectedOptions, NO_ACTIVITY);
        // Toggle the option's existence in the array.
        this.selectedOptions = xor(this.selectedOptions, [option]);
      }

      this.updateQuerystring();
    },
  },
  NO_ACTIVITY,
};
</script>

<template>
  <filter-body
    :name="filter.name"
    :selected-options="selectedOptionsOrAll"
    :show-search-box="false"
  >
    <filter-item
      :is-checked="isNoOptionsSelected"
      :text="filter.allOption.name"
      :data-testid="`option:${filter.allOption.name}`"
      @click="deselectAllOptions"
    />
    <filter-item
      :is-checked="isSelected($options.NO_ACTIVITY)"
      :text="$options.NO_ACTIVITY.name"
      :data-testid="`option:${$options.NO_ACTIVITY.name}`"
      @click="toggleOption($options.NO_ACTIVITY)"
    />
    <gl-dropdown-divider />
    <filter-item
      v-for="option in multiselectOptions"
      :key="option.name"
      :is-checked="isSelected(option)"
      :text="option.name"
      :data-testid="`option:${option.name}`"
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
