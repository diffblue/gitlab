<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
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
  computed: {
    options() {
      return this.auditEventDefinitions.map((event) => ({
        value: event.event_name,
        text: humanize(event.event_name),
      }));
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
  },
  i18n: { ...AUDIT_STREAMS_FILTERING },
};
</script>

<template>
  <gl-collapsible-listbox
    :items="options"
    :selected="value"
    :toggle-text="toggleText"
    :header-text="$options.i18n.SELECT_EVENTS"
    :show-select-all-button-label="$options.i18n.SELECT_ALL"
    :reset-button-label="$options.i18n.UNSELECT_ALL"
    multiple
    toggle-class="gl-max-w-full"
    class="gl-max-w-full"
    @select="$emit('input', $event)"
    @reset="$emit('input', [])"
    @select-all="selectAll"
  />
</template>
