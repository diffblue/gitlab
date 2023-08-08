<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__, n__ } from '~/locale';
import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';
import { VULNERABILITY_STATE_OBJECTS, DISMISSAL_REASONS } from 'ee/vulnerabilities/constants';
import QuerystringSync from './querystring_sync.vue';
import { ALL_ID as ALL_STATUS_VALUE } from './constants';

const { detected, confirmed, dismissed, resolved } = VULNERABILITY_STATE_OBJECTS;
// For backwards compatibility with existing bookmarks, the "value" needs to be capitalized.
export const GROUPS = [
  {
    text: '',
    textSrOnly: true,
    options: [
      { value: ALL_STATUS_VALUE, text: s__('SecurityReports|All statuses') },
      { value: detected.state.toUpperCase(), text: detected.buttonText },
      { value: confirmed.state.toUpperCase(), text: confirmed.buttonText },
      { value: resolved.state.toUpperCase(), text: resolved.buttonText },
    ],
  },
  {
    text: s__('SecurityReports|Dismissed as...'),
    options: [
      { value: dismissed.state.toUpperCase(), text: s__('SecurityReports|All dismissal reasons') },
      ...Object.entries(DISMISSAL_REASONS).map(([value, text]) => ({
        value: value.toUpperCase(),
        text,
      })),
    ],
  },
];

const OPTIONS = [...GROUPS[0].options, ...GROUPS[1].options];
const VALID_VALUES = OPTIONS.map(({ value }) => value);
const DEFAULT_VALUES = [detected.state.toUpperCase(), confirmed.state.toUpperCase()];

const ALL_DISMISSED_VALUE = GROUPS[1].options[0].value;
const DISMISSAL_REASON_VALUES = GROUPS[1].options.slice(1).map(({ value }) => value);

export default {
  components: {
    GlCollapsibleListbox,
    QuerystringSync,
  },
  data: () => ({
    selected: DEFAULT_VALUES,
  }),
  computed: {
    toggleText() {
      // "All dismissal reasons" option is selected
      if (this.selected.length === 1 && this.selected[0] === ALL_DISMISSED_VALUE) {
        return s__('SecurityReports|Dismissed (all reasons)');
      }
      // Dismissal reason(s) is selected
      if (this.selected.every((value) => DISMISSAL_REASON_VALUES.includes(value))) {
        return n__(`Dismissed (%d reason)`, `Dismissed (%d reasons)`, this.selected.length);
      }

      return getSelectedOptionsText({ options: OPTIONS, selected: this.selected });
    },
  },
  watch: {
    selected: {
      immediate: true,
      handler() {
        const dismissalReason = this.selected.filter((value) =>
          DISMISSAL_REASON_VALUES.includes(value),
        );
        const state = this.selected.filter(
          (value) => !DISMISSAL_REASON_VALUES.includes(value) && value !== ALL_STATUS_VALUE,
        );

        this.$emit('filter-changed', { state, dismissalReason });
      },
    },
  },
  methods: {
    updateSelected(selected) {
      const selectedValue = selected.at(-1);

      const noneSelected = selected.length <= 0;
      const allStatusSelected = selectedValue === ALL_STATUS_VALUE;
      const allDismissedSelected = selectedValue === ALL_DISMISSED_VALUE;
      const dismissalReasonSelected = DISMISSAL_REASON_VALUES.includes(selectedValue);

      const filterOutValues = (selectedVal, valuesToDeselect) => {
        return selectedVal.filter((s) => !valuesToDeselect.includes(s));
      };

      if (noneSelected || allStatusSelected) {
        this.selected = [ALL_STATUS_VALUE];
      } else if (allDismissedSelected) {
        this.selected = filterOutValues(selected, [...DISMISSAL_REASON_VALUES, ALL_STATUS_VALUE]);
      } else if (dismissalReasonSelected) {
        this.selected = filterOutValues(selected, [ALL_DISMISSED_VALUE, ALL_STATUS_VALUE]);
      } else {
        this.selected = filterOutValues(selected, [ALL_STATUS_VALUE]);
      }
    },
    updateSelectedFromQS(selected) {
      if (selected.includes(ALL_STATUS_VALUE)) {
        this.selected = [ALL_STATUS_VALUE];
      } else if (selected.length > 0) {
        this.selected = selected;
      } else {
        this.selected = DEFAULT_VALUES;
      }
    },
  },
  i18n: {
    label: s__('SecurityReports|Status'),
  },
  GROUPS,
  VALID_VALUES,
};
</script>

<template>
  <div>
    <querystring-sync
      querystring-key="state"
      :value="selected"
      :valid-values="$options.VALID_VALUES"
      @input="updateSelectedFromQS"
    />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-collapsible-listbox
      :header-text="$options.i18n.label"
      block
      multiple
      :items="$options.GROUPS"
      :selected="selected"
      :toggle-text="toggleText"
      data-testid="filter-status-dropdown"
      @select="updateSelected"
    />
  </div>
</template>
