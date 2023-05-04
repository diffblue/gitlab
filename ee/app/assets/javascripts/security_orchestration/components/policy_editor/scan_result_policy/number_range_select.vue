<script>
import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ANY_OPERATOR, NUMBER_RANGE_I18N_MAP } from '../constants';

export default {
  components: {
    GlCollapsibleListbox,
    GlFormInput,
  },
  props: {
    value: {
      type: Number,
      required: false,
      default: 0,
    },
    id: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    operators: {
      type: Array,
      required: true,
    },
    selected: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      operator: this.selected || this.operators[0],
    };
  },
  computed: {
    listBoxItems() {
      return this.operators.map((operator) => ({
        value: operator,
        text: NUMBER_RANGE_I18N_MAP[operator],
      }));
    },
    showNumberInput() {
      return this.operator !== ANY_OPERATOR;
    },
    inputId() {
      return `${this.id}-number-range-input`;
    },
  },
  methods: {
    onSelect(item) {
      this.operator = item;
      this.$emit('operator-change', item);
    },
  },
  i18n: {
    headerText: s__('ScanResultPolicy|Choose an option'),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-gap-3">
    <gl-collapsible-listbox
      :items="listBoxItems"
      :header-text="$options.i18n.headerText"
      :selected="operator"
      :data-testid="`${id}-operator`"
      @select="onSelect"
    >
      <template #list-item="{ item }">
        {{ item.text }}
      </template>
    </gl-collapsible-listbox>
    <template v-if="showNumberInput">
      <label :for="inputId" class="gl-sr-only">{{ label }}</label>
      <gl-form-input
        :id="inputId"
        :value="value"
        type="number"
        class="gl-w-11!"
        :min="0"
        :data-testid="`${id}-input`"
        @input="$emit('input', $event)"
      />
    </template>
  </div>
</template>
