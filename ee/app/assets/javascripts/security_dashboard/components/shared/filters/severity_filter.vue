<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';
import { SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import QuerystringSync from './querystring_sync.vue';
import { ALL_ID } from './constants';

// For backwards compatibility with existing bookmarks, the ID needs to be capitalized.
export const SEVERITY_LEVEL_ITEMS = Object.entries(SEVERITY_LEVELS).map(([id, text]) => ({
  value: id.toUpperCase(),
  text,
}));

export const FILTER_ITEMS = [
  {
    value: ALL_ID,
    text: s__('SecurityReports|All severities'),
  },
  ...SEVERITY_LEVEL_ITEMS,
];

const VALID_IDS = SEVERITY_LEVEL_ITEMS.map(({ value }) => value);

export default {
  components: { GlCollapsibleListbox, QuerystringSync },
  data: () => ({
    selectedIds: [ALL_ID],
  }),
  computed: {
    toggleText() {
      return getSelectedOptionsText({ options: FILTER_ITEMS, selected: this.selectedIds });
    },
  },
  watch: {
    selectedIds: {
      handler() {
        this.$emit('filter-changed', {
          severity: this.selectedIds.filter((value) => value !== ALL_ID),
        });
      },
    },
  },
  methods: {
    updateSelected(selected) {
      if (!selected.length || selected.at(-1) === ALL_ID) {
        this.selectedIds = [ALL_ID];
      } else {
        this.selectedIds = selected.filter((value) => value !== ALL_ID);
      }
    },
  },
  i18n: {
    label: s__('SecurityReports|Severity'),
  },
  FILTER_ITEMS,
  VALID_IDS,
};
</script>

<template>
  <div>
    <querystring-sync
      :value="selectedIds"
      querystring-key="severity"
      :valid-values="$options.VALID_IDS"
      @input="updateSelected"
    />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-collapsible-listbox
      :header-text="$options.i18n.label"
      :items="$options.FILTER_ITEMS"
      :selected="selectedIds"
      :toggle-text="toggleText"
      multiple
      block
      @select="updateSelected"
    />
  </div>
</template>
