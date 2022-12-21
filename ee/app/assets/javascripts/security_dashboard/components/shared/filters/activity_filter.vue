<script>
import { GlDropdown, GlDropdownDivider, GlDropdownSectionHeader, GlBadge } from '@gitlab/ui';
import { without } from 'lodash';
import { s__ } from '~/locale';
import FilterItem from './filter_item.vue';
import QuerystringSync from './querystring_sync.vue';
import DropdownButtonText from './dropdown_button_text.vue';
import { ALL_ID } from './constants';

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
  components: {
    FilterItem,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlBadge,
    QuerystringSync,
    DropdownButtonText,
  },
  data: () => ({
    selected: [],
  }),
  computed: {
    selectedItemNames() {
      const items = Object.values(ITEMS).filter(({ id }) => this.selected.includes(id));
      return items.length ? items.map(({ name }) => name) : [this.$options.i18n.allItemsText];
    },
  },
  watch: {
    selected() {
      let hasResolution;
      let hasIssues;
      // The above variables can be true, false, or unset, so we need to use if/else-if here instead
      // of if/else.
      if (this.selected.includes(ITEMS.NO_LONGER_DETECTED.id)) {
        hasResolution = true;
      } else if (this.selected.includes(ITEMS.STILL_DETECTED.id)) {
        hasResolution = false;
      }

      if (this.selected.includes(ITEMS.HAS_ISSUE.id)) {
        hasIssues = true;
      } else if (this.selected.includes(ITEMS.DOES_NOT_HAVE_ISSUE.id)) {
        hasIssues = false;
      }

      this.$emit('filter-changed', { hasResolution, hasIssues });
    },
  },
  methods: {
    deselectAll() {
      this.selected = [];
    },
    toggleSelected(group, id) {
      // If the clicked ID is already selected, unselect it.
      if (this.selected.includes(id)) {
        this.selected = without(this.selected, id);
      }
      // Otherwise, unselect all the IDs in the group, then select the clicked ID.
      else {
        const groupItemIds = group.items.map((item) => item.id);
        this.selected = without(this.selected, ...groupItemIds).concat(id);
      }
    },
  },
  i18n: {
    label: s__('SecurityReports|Activity'),
    allItemsText: s__('SecurityReports|All activity'),
  },
  GROUPS,
  ALL_ID,
};
</script>

<template>
  <div>
    <querystring-sync v-model="selected" querystring-key="activity" />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-dropdown
      :header-text="$options.i18n.label"
      block
      toggle-class="gl-mb-0"
      data-qa-selector="filter_activity_dropdown"
    >
      <template #button-text>
        <dropdown-button-text :items="selectedItemNames" :name="$options.i18n.label" />
      </template>

      <filter-item
        :is-checked="!selected.length"
        :text="$options.i18n.allItemsText"
        :data-testid="$options.ALL_ID"
        @click="deselectAll"
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
          v-for="{ id, name } in group.items"
          :key="id"
          :is-checked="selected.includes(id)"
          :text="name"
          :data-testid="id"
          @click="toggleSelected(group, id)"
        />
      </template>
    </gl-dropdown>
  </div>
</template>
