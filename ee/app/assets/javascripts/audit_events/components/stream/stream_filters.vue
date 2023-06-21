<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { humanize } from '~/lib/utils/text_utility';
import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';
import { __ } from '~/locale';
import { AUDIT_STREAMS_FILTERING } from '../../constants';

const MAX_OPTIONS_SHOWN = 3;

export default {
  components: {
    GlCollapsibleListbox,
  },
  inject: ['auditEventDefinitions'],
  props: {
    value: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    options() {
      return this.auditEventDefinitions.map((event) => ({
        value: event.event_name,
        text: humanize(event.event_name),
      }));
    },
    filteredOptions() {
      if (!this.searchTerm) {
        return this.options;
      }

      return this.options.filter(({ text }) => text.toLowerCase().includes(this.searchTerm));
    },
    toggleText() {
      return getSelectedOptionsText({
        options: this.options,
        selected: this.value,
        placeholder: this.$options.i18n.SELECT_EVENTS,
        maxOptionsShown: MAX_OPTIONS_SHOWN,
      });
    },
  },
  methods: {
    selectAll() {
      this.$emit(
        'input',
        this.options.map((option) => option.value),
      );
    },
    updateSearchTerm(searchTerm) {
      this.searchTerm = searchTerm.toLowerCase();
    },
  },
  i18n: {
    ...AUDIT_STREAMS_FILTERING,
    noResultsText: __('No results found'),
    searchPlaceholder: __('Search'),
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :items="filteredOptions"
    :selected="value"
    :toggle-text="toggleText"
    :header-text="$options.i18n.SELECT_EVENTS"
    :show-select-all-button-label="$options.i18n.SELECT_ALL"
    :reset-button-label="$options.i18n.UNSELECT_ALL"
    :no-results-text="$options.i18n.noResultsText"
    :search-placeholder="$options.i18n.searchPlaceholder"
    multiple
    searchable
    toggle-class="gl-max-w-full"
    class="gl-max-w-full"
    @select="$emit('input', $event)"
    @reset="$emit('input', [])"
    @select-all="selectAll"
    @search="updateSearchTerm"
  />
</template>
