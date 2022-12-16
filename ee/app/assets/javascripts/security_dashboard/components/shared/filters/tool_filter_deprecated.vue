<script>
import { GlDropdown } from '@gitlab/ui';
import { xor } from 'lodash';
import { REPORT_TYPES_WITH_MANUALLY_ADDED } from 'ee/security_dashboard/store/constants';
import { s__ } from '~/locale';
import FilterItem from './filter_item.vue';
import DropdownButtonText from './dropdown_button_text.vue';
import QuerystringSync from './querystring_sync.vue';
import { ALL_ID } from './constants';

// For backwards compatibility with existing bookmarks, the ID needs to be capitalized.
export const DROPDOWN_OPTIONS = Object.entries(REPORT_TYPES_WITH_MANUALLY_ADDED).map(
  ([id, text]) => ({
    id: id.toUpperCase(),
    text,
  }),
);

export default {
  components: { FilterItem, GlDropdown, DropdownButtonText, QuerystringSync },
  data() {
    return {
      selected: [],
    };
  },
  computed: {
    selectedItemTexts() {
      const options = DROPDOWN_OPTIONS.filter(({ id }) => this.selected.includes(id));
      // Return the text for selected items, or all items if nothing is selected.
      return options.length ? options.map(({ text }) => text) : [this.$options.i18n.allItemsText];
    },
  },
  watch: {
    selected() {
      this.$emit('filter-changed', { reportType: this.selected });
    },
  },
  methods: {
    deselectAll() {
      this.selected = [];
    },
    toggleSelected(id) {
      this.selected = xor(this.selected, [id]);
    },
  },
  i18n: {
    label: s__('SecurityReports|Tool'),
    allItemsText: s__('SecurityReports|All tools'),
  },
  DROPDOWN_OPTIONS,
  ALL_ID,
};
</script>

<template>
  <div>
    <querystring-sync v-model="selected" querystring-key="reportType" />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-dropdown
      :header-text="$options.i18n.label"
      block
      toggle-class="gl-mb-0"
      menu-class="dropdown-extended-height"
    >
      <template #button-text>
        <dropdown-button-text :items="selectedItemTexts" :name="$options.i18n.label" />
      </template>
      <filter-item
        :is-checked="!selected.length"
        :text="$options.i18n.allItemsText"
        :data-testid="$options.ALL_ID"
        @click="deselectAll"
      />
      <filter-item
        v-for="{ id, text } in $options.DROPDOWN_OPTIONS"
        :key="id"
        :data-testid="id"
        :is-checked="selected.includes(id)"
        :text="text"
        @click="toggleSelected(id)"
      />
    </gl-dropdown>
  </div>
</template>
