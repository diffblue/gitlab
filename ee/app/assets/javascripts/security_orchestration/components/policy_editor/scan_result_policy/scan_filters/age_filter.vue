<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import BaseLayoutComponent from '../base_layout/base_layout_component.vue';
import NumberRangeSelect from '../number_range_select.vue';
import { ANY_OPERATOR, VULNERABILITY_AGE_OPERATORS } from '../../constants';
import { AGE, AGE_DAY, AGE_INTERVALS } from './constants';

export default {
  i18n: {
    label: s__('ScanResultPolicy|Age is:'),
    headerText: s__('ScanResultPolicy|Choose an option'),
  },
  name: 'AgeFilter',
  components: {
    BaseLayoutComponent,
    NumberRangeSelect,
    GlCollapsibleListbox,
  },
  props: {
    selected: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    showRemoveButton: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    showInterval() {
      return this.operator !== ANY_OPERATOR;
    },
    value() {
      return this.selected.value || 0;
    },
    operator() {
      return this.selected.operator || ANY_OPERATOR;
    },
    interval() {
      return this.selected.interval || AGE_DAY;
    },
  },
  methods: {
    remove() {
      this.$emit('remove', AGE);
    },
    emitChange(data) {
      this.$emit('input', {
        operator: this.operator,
        value: this.value,
        interval: this.interval,
        ...data,
      });
    },
  },
  VULNERABILITY_AGE_OPERATORS,
  AGE_INTERVALS,
};
</script>

<template>
  <base-layout-component
    class="gl-w-full gl-bg-white"
    content-class="gl-bg-white gl-rounded-base gl-p-5"
    :show-label="false"
    :show-remove-button="showRemoveButton"
    @remove="remove"
  >
    <template #selector>
      <label class="gl-mb-0" :title="$options.i18n.label">{{ $options.i18n.label }}</label>
      <number-range-select
        id="vulnerability-age-select"
        :value="value"
        :label="$options.i18n.headerText"
        :selected="operator"
        :operators="$options.VULNERABILITY_AGE_OPERATORS"
        @input="emitChange({ value: $event })"
        @operator-change="emitChange({ operator: $event })"
      />
      <gl-collapsible-listbox
        v-if="showInterval"
        :selected="interval"
        :header-text="$options.i18n.headerText"
        :items="$options.AGE_INTERVALS"
        @select="emitChange({ interval: $event })"
      />
    </template>
  </base-layout-component>
</template>
