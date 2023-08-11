<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import AttributeFilter from './attribute_filter.vue';
import { VULNERABILITY_ATTRIBUTES } from './constants';

export default {
  i18n: {
    andOperator: __('and'),
    label: s__('ScanResultPolicy|Attribute:'),
    labelTooltip: s__('ScanResultPolicy|Attributes are automatically applied by the scanners'),
  },
  name: 'AttributeFilters',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    AttributeFilter,
  },
  props: {
    selected: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    selectedItems() {
      return Object.entries(this.selected).map(([attribute, value]) => ({ attribute, value }));
    },
    selectionDisabled() {
      return this.selectedItems.length >= VULNERABILITY_ATTRIBUTES.length;
    },
  },
  methods: {
    removeFilter(attribute) {
      this.$emit('remove', attribute);
    },
    emitValueChange(attribute, newValue) {
      this.$emit('input', { ...this.selected, [attribute]: newValue });
    },
    emitAttributeChange(oldAttribute, value, newAttribute) {
      const { [oldAttribute]: attributeToRemove, ...attributes } = this.selected;
      this.$emit('input', { ...attributes, [newAttribute]: value });
    },
  },
};
</script>

<template>
  <div class="gl-w-full gl-bg-white gl-rounded-base">
    <attribute-filter
      v-for="({ attribute, value }, idx) in selectedItems"
      :key="attribute"
      :disabled="selectionDisabled"
      :attribute="attribute"
      :operator-value="value"
      :class="{ 'gl-pt-0': idx > 0 }"
      @input="emitValueChange(attribute, $event)"
      @attribute-change="emitAttributeChange(attribute, value, $event)"
      @remove="removeFilter"
    >
      <template #label>
        <label v-if="idx === 0" v-gl-tooltip class="gl-mb-0" :title="$options.i18n.labelTooltip">{{
          $options.i18n.label
        }}</label>
        <label v-else class="gl-mb-0 gl-text-transform-uppercase gl-w-11 gl-font-weight-normal">{{
          $options.i18n.andOperator
        }}</label>
      </template>
    </attribute-filter>
  </div>
</template>
