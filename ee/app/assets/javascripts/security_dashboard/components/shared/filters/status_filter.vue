<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';
import QuerystringSync from './querystring_sync.vue';
import { ALL_ID } from './constants';

const { detected, confirmed, dismissed, resolved } = VULNERABILITY_STATE_OBJECTS;
// For backwards compatibility with existing bookmarks, the ID needs to be capitalized.
export const DROPDOWN_OPTIONS = [
  { value: ALL_ID, text: s__('SecurityReports|All statuses') },
  { value: detected.state.toUpperCase(), text: detected.buttonText },
  { value: confirmed.state.toUpperCase(), text: confirmed.buttonText },
  { value: dismissed.state.toUpperCase(), text: dismissed.buttonText },
  { value: resolved.state.toUpperCase(), text: resolved.buttonText },
];
export const VALID_IDS = DROPDOWN_OPTIONS.map(({ value }) => value);
export const DEFAULT_IDS = [VALID_IDS[1], VALID_IDS[2]];

export default {
  components: {
    GlCollapsibleListbox,
    QuerystringSync,
  },
  data: () => ({
    selected: DEFAULT_IDS,
  }),
  computed: {
    toggleText() {
      return getSelectedOptionsText({ options: DROPDOWN_OPTIONS, selected: this.selected });
    },
  },
  watch: {
    selected: {
      immediate: true,
      handler() {
        this.$emit('filter-changed', {
          state: this.selected.filter((value) => value !== ALL_ID),
        });
      },
    },
  },
  methods: {
    updateSelected(selected) {
      if (selected.length <= 0 || selected.at(-1) === ALL_ID) {
        this.selected = [ALL_ID];
      } else {
        this.selected = selected.filter((value) => value !== ALL_ID);
      }
    },
    updateSelectedFromQS(selected) {
      if (selected.includes(ALL_ID)) {
        this.selected = [ALL_ID];
      } else if (selected.length > 0) {
        this.selected = selected;
      } else {
        this.selected = DEFAULT_IDS;
      }
    },
  },
  i18n: {
    label: s__('SecurityReports|Status'),
  },
  DROPDOWN_OPTIONS,
  VALID_IDS,
};
</script>

<template>
  <div>
    <querystring-sync
      querystring-key="state"
      :value="selected"
      :valid-values="$options.VALID_IDS"
      @input="updateSelectedFromQS"
    />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-collapsible-listbox
      :header-text="$options.i18n.label"
      block
      multiple
      data-qa-selector="filter_status_dropdown"
      :items="$options.DROPDOWN_OPTIONS"
      :selected="selected"
      :toggle-text="toggleText"
      @select="updateSelected"
    />
  </div>
</template>
