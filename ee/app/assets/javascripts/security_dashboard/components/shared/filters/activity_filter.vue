<script>
import { GlDropdownDivider, GlDropdownSectionHeader, GlBadge } from '@gitlab/ui';
import { s__ } from '~/locale';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';
import SimpleFilter from './simple_filter.vue';

export const ITEMS = {
  STILL_DETECTED: {
    id: 'STILL_DETECTED',
    name: s__('SecurityReports|Still detected'),
  },
  NO_LONGER_DETECTED: {
    id: 'NO_LONGER_DETECTED',
    name: s__('SecurityReports|No longer detected'),
  },
  HAS_ISSUE: {
    id: 'HAS_ISSUE',
    name: s__('SecurityReports|Has issue'),
  },
  DOES_NOT_HAVE_ISSUE: {
    id: 'DOES_NOT_HAVE_ISSUE',
    name: s__('SecurityReports|Does not have issue'),
  },
};

export const GROUPS = [
  {
    header: {
      name: s__('SecurityReports|Detection'),
      icon: 'check-circle-dashed',
      variant: 'info',
    },
    items: [ITEMS.STILL_DETECTED, ITEMS.NO_LONGER_DETECTED],
  },
  {
    header: {
      name: s__('SecurityReports|Issue'),
      icon: 'issues',
    },
    items: [ITEMS.HAS_ISSUE, ITEMS.DOES_NOT_HAVE_ISSUE],
  },
];

export default {
  components: { FilterBody, FilterItem, GlDropdownDivider, GlDropdownSectionHeader, GlBadge },
  extends: SimpleFilter,
  computed: {
    options() {
      return Object.values(ITEMS);
    },
    filterObject() {
      let hasResolution;
      let hasIssues;
      // The above variables can be true, false, or unset, so we need to use if/else-if here instead
      // of if/else.
      if (this.isSelected(ITEMS.NO_LONGER_DETECTED)) {
        hasResolution = true;
      } else if (this.isSelected(ITEMS.STILL_DETECTED)) {
        hasResolution = false;
      }

      if (this.isSelected(ITEMS.HAS_ISSUE)) {
        hasIssues = true;
      } else if (this.isSelected(ITEMS.DOES_NOT_HAVE_ISSUE)) {
        hasIssues = false;
      }

      return { hasResolution, hasIssues };
    },
  },
  methods: {
    toggleOption(group, item) {
      // If the clicked item is already selected, unselect it.
      if (this.selectedOptions.includes(item)) {
        this.selectedOptions = this.selectedOptions.filter((selected) => selected !== item);
      }
      // Otherwise, unselect all the items in the group, then select the clicked item.
      else {
        this.selectedOptions = this.selectedOptions
          .filter((selected) => !group.items.includes(selected))
          .concat(item);
      }

      this.updateQuerystring();
    },
  },
  GROUPS,
};
</script>

<template>
  <filter-body :name="filter.name" :selected-options="selectedOptionsOrAll">
    <filter-item
      :is-checked="isNoOptionsSelected"
      :text="filter.allOption.name"
      :data-testid="`option-${filter.allOption.id}`"
      @click="deselectAllOptions"
    />

    <template v-for="group in $options.GROUPS">
      <gl-dropdown-divider :key="`divider-${group.header.name}`" />

      <gl-dropdown-section-header
        :key="`header-${group.header.name}`"
        :data-testid="`header-${group.header.name}`"
      >
        <div class="gl--flex-center">
          <div class="gl-flex-grow-1">{{ group.header.name }}</div>
          <gl-badge :icon="group.header.icon" :variant="group.header.variant" />
        </div>
      </gl-dropdown-section-header>

      <filter-item
        v-for="item in group.items"
        :key="item.id"
        :is-checked="isSelected(item)"
        :text="item.name"
        :data-testid="`option-${item.id}`"
        @click="toggleOption(group, item)"
      />
    </template>
  </filter-body>
</template>
