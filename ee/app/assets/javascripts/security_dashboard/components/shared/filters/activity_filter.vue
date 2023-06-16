<script>
import { GlBadge, GlCollapsibleListbox } from '@gitlab/ui';
import { without } from 'lodash';
import { s__ } from '~/locale';
import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';
import QuerystringSync from './querystring_sync.vue';
import { ALL_ID } from './constants';

export const ITEMS = {
  STILL_DETECTED: {
    value: 'STILL_DETECTED',
    text: s__('SecurityReports|Still detected'),
  },
  NO_LONGER_DETECTED: {
    value: 'NO_LONGER_DETECTED',
    text: s__('SecurityReports|No longer detected'),
  },
  HAS_ISSUE: {
    value: 'HAS_ISSUE',
    text: s__('SecurityReports|Has issue'),
  },
  DOES_NOT_HAVE_ISSUE: {
    value: 'DOES_NOT_HAVE_ISSUE',
    text: s__('SecurityReports|Does not have issue'),
  },
};

export const GROUPS = [
  {
    text: '',
    options: [
      {
        value: ALL_ID,
        text: s__('SecurityReports|All activity'),
      },
    ],
    textSrOnly: true,
  },
  {
    text: s__('SecurityReports|Detection'),
    options: [ITEMS.STILL_DETECTED, ITEMS.NO_LONGER_DETECTED],
    icon: 'check-circle-dashed',
    variant: 'info',
  },
  {
    text: s__('SecurityReports|Issue'),
    options: [ITEMS.HAS_ISSUE, ITEMS.DOES_NOT_HAVE_ISSUE],
    icon: 'issues',
  },
];

export default {
  components: {
    GlBadge,
    QuerystringSync,
    GlCollapsibleListbox,
  },
  data: () => ({
    selected: [],
  }),
  computed: {
    toggleText() {
      return getSelectedOptionsText({
        options: Object.values(ITEMS),
        selected: this.selected,
        placeholder: this.$options.i18n.allItemsText,
      });
    },
    selectedItems() {
      return this.selected.length ? this.selected : [ALL_ID];
    },
  },
  watch: {
    selected() {
      let hasResolution;
      let hasIssues;
      // The above variables can be true, false, or unset, so we need to use if/else-if here instead
      // of if/else.
      if (this.selected.includes(ITEMS.NO_LONGER_DETECTED.value)) {
        hasResolution = true;
      } else if (this.selected.includes(ITEMS.STILL_DETECTED.value)) {
        hasResolution = false;
      }

      if (this.selected.includes(ITEMS.HAS_ISSUE.value)) {
        hasIssues = true;
      } else if (this.selected.includes(ITEMS.DOES_NOT_HAVE_ISSUE.value)) {
        hasIssues = false;
      }

      this.$emit('filter-changed', { hasResolution, hasIssues });
    },
  },
  methods: {
    getGroupFromItem(value) {
      return GROUPS.find((group) => group.options.map((option) => option.value).includes(value));
    },
    updateSelected(selected) {
      const selectedValue = selected?.at(-1);

      // If the ALL_ID option is being selected (last item in selected) or
      // it's clicked when already selected, the selected items should be empty
      if (selectedValue === ALL_ID) {
        this.selected = [];
        return;
      }

      const selectedWithoutAll = without(selected, ALL_ID);
      // Test whether a new item is selected by checking if `selected`
      // (without ALL_ID option) length is larger than `this.selected` length.
      const isSelecting = selectedWithoutAll.length > this.selected.length;
      // If a new item is selected, clear other selected items from the same group and select the new item.
      if (isSelecting) {
        const group = this.getGroupFromItem(selectedValue);
        const groupItemIds = group.options.map((option) => option.value);
        this.selected = without(this.selected, ...groupItemIds).concat(selectedValue);
      }
      // Otherwise, if item is being unselected, just take `selectedWithoutAll` as `this.selected`.
      else {
        this.selected = selectedWithoutAll;
      }
    },
  },
  i18n: {
    label: s__('SecurityReports|Activity'),
    allItemsText: s__('SecurityReports|All activity'),
  },
  GROUPS,
};
</script>

<template>
  <div>
    <querystring-sync v-model="selected" querystring-key="activity" />
    <label class="gl-mb-2">{{ $options.i18n.label }}</label>
    <gl-collapsible-listbox
      :items="$options.GROUPS"
      :selected="selectedItems"
      :header-text="$options.i18n.label"
      :toggle-text="toggleText"
      multiple
      block
      data-qa-selector="filter_activity_dropdown"
      @select="updateSelected"
    >
      <template #group-label="{ group }">
        <div
          v-if="group.icon"
          class="gl--flex-center gl-pr-4"
          :data-testid="`header-${group.text}`"
        >
          <div class="gl-flex-grow-1">{{ group.text }}</div>
          <gl-badge :icon="group.icon" :variant="group.variant" />
        </div>
      </template>
    </gl-collapsible-listbox>
  </div>
</template>
