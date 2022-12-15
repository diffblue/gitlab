<script>
import { GlDropdown } from '@gitlab/ui';
import { xor } from 'lodash';
import { s__ } from '~/locale';
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';
import DropdownButtonText from './dropdown_button_text.vue';
import QuerystringSync from './querystring_sync.vue';
import FilterItem from './filter_item.vue';
import { ALL_ID } from './constants';

const { detected, confirmed, dismissed, resolved } = VULNERABILITY_STATE_OBJECTS;
// For backwards compatibility with existing bookmarks, the ID needs to be capitalized.
export const DROPDOWN_OPTIONS = [
  { id: detected.state.toUpperCase(), text: detected.buttonText },
  { id: confirmed.state.toUpperCase(), text: confirmed.buttonText },
  { id: dismissed.state.toUpperCase(), text: dismissed.buttonText },
  { id: resolved.state.toUpperCase(), text: resolved.buttonText },
];
export const VALID_IDS = [ALL_ID, ...DROPDOWN_OPTIONS.map(({ id }) => id)];
export const DEFAULT_IDS = [detected.state.toUpperCase(), confirmed.state.toUpperCase()];

export default {
  components: { GlDropdown, DropdownButtonText, QuerystringSync, FilterItem },
  data: () => ({
    selected: DEFAULT_IDS,
  }),
  computed: {
    selectedIds() {
      return this.selected.length ? this.selected : [ALL_ID];
    },
    selectedItemTexts() {
      const options = DROPDOWN_OPTIONS.filter(({ id }) => this.selected.includes(id));
      // Return the text for selected items, or all items if nothing is selected.
      return options.length ? options.map(({ text }) => text) : [this.$options.i18n.allItemsText];
    },
  },
  watch: {
    selected: {
      immediate: true,
      handler() {
        this.$emit('filter-changed', { state: this.selected });
      },
    },
  },
  methods: {
    deselectAll() {
      this.selected = [];
    },
    toggleSelected(id) {
      this.selected = xor(this.selected, [id]);
    },
    setSelected(ids) {
      if (ids.includes(ALL_ID)) {
        this.selected = [];
      } else if (!ids.length) {
        this.selected = DEFAULT_IDS;
      } else {
        this.selected = ids;
      }
    },
  },
  i18n: {
    label: s__('SecurityReports|Status'),
    allItemsText: s__('SecurityReports|All statuses'),
  },
  DROPDOWN_OPTIONS,
  VALID_IDS,
  ALL_ID,
};
</script>

<template>
  <div>
    <querystring-sync
      querystring-key="state"
      :value="selectedIds"
      :valid-values="$options.VALID_IDS"
      @input="setSelected"
    />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-dropdown :header-text="$options.i18n.label" block toggle-class="gl-mb-0">
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
