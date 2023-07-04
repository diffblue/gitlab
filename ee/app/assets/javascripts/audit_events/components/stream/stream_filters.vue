<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { groupBy, partition } from 'lodash';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { __ } from '~/locale';
import { humanize } from '~/lib/utils/text_utility';
import { getSelectedOptionsText } from '~/lib/utils/listbox_helpers';
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
    humanizedEvents() {
      return this.auditEventDefinitions.map((event) => ({
        value: event.event_name,
        text: humanize(event.event_name),
        category: humanize(event.feature_category),
      }));
    },
    filteredEvents() {
      if (this.searchTerm) {
        return fuzzaldrinPlus.filter(this.humanizedEvents, this.searchTerm, { key: 'text' });
      }

      return this.humanizedEvents;
    },
    partitionedEvents() {
      return partition(this.filteredEvents, ({ value }) => this.value.includes(value));
    },
    options() {
      const [selectedEvents, unselectedEvents] = this.partitionedEvents;
      const selectedOptions = {
        text: __('Selected'),
        options: selectedEvents,
      };
      const groupedEvents = groupBy(unselectedEvents, 'category');
      const unselectedOptions = Object.entries(groupedEvents).map(([category, events]) => ({
        text: category,
        options: events,
      }));

      return selectedEvents.length ? [selectedOptions, ...unselectedOptions] : unselectedOptions;
    },
    toggleText() {
      return getSelectedOptionsText({
        options: this.humanizedEvents,
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
        this.humanizedEvents.map((option) => option.value),
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
    id="audit-event-type-filter"
    :items="options"
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
