<script>
import { GlCollapsibleListbox, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import { __, s__ } from '~/locale';
import BaseLayoutComponent from '../base_layout/base_layout_component.vue';
import {
  FIX_AVAILABLE,
  VULNERABILITY_ATTRIBUTE_OPERATORS,
  VULNERABILITY_ATTRIBUTES,
} from './constants';

export default {
  i18n: {
    label: s__('ScanResultPolicy|Attribute is:'),
    headerText: __('Choose an option'),
    fixAvailableTooltip: s__(
      'ScanResultPolicy|Fix available is only applicable to container and dependency scanning',
    ),
  },
  name: 'AttributeFilter',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    BaseLayoutComponent,
    GlCollapsibleListbox,
    GlIcon,
  },
  props: {
    operatorValue: {
      type: Boolean,
      required: true,
    },
    attribute: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    operatorSelectedValue() {
      return this.operatorValue ? 'true' : 'false';
    },
    showInformationIcon() {
      return this.attribute === FIX_AVAILABLE;
    },
  },
  methods: {
    remove() {
      this.$emit('remove', this.attribute);
    },
    emitValueChange(value) {
      this.$emit('input', parseBoolean(value));
    },
    emitAttributeChange(attribute) {
      this.$emit('attribute-change', attribute);
    },
  },
  VULNERABILITY_ATTRIBUTES,
  VULNERABILITY_ATTRIBUTE_OPERATORS,
};
</script>

<template>
  <base-layout-component class="gl-w-full gl-bg-white!" @remove="remove">
    <template #selector>
      <slot name="label">
        <label class="gl-mb-0" :title="$options.i18n.label">{{ $options.i18n.label }}</label>
      </slot>
      <gl-collapsible-listbox
        :selected="operatorSelectedValue"
        :header-text="$options.i18n.headerText"
        :items="$options.VULNERABILITY_ATTRIBUTE_OPERATORS"
        data-testid="vulnerability-attribute-operator-select"
        @select="emitValueChange($event)"
      />
      <gl-collapsible-listbox
        :selected="attribute"
        :disabled="disabled"
        :header-text="$options.i18n.headerText"
        :items="$options.VULNERABILITY_ATTRIBUTES"
        data-testid="vulnerability-attribute-select"
        @select="emitAttributeChange($event)"
      />
      <gl-icon
        v-if="showInformationIcon"
        v-gl-tooltip
        name="information-o"
        :title="$options.i18n.fixAvailableTooltip"
        class="gl-text-gray-500 gl-ml-2"
      />
    </template>
  </base-layout-component>
</template>
