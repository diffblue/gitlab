<script>
import { GlCollapsibleListbox, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';
import GenericBaseLayoutComponent from '../../generic_base_layout_component.vue';
import { RULE_MODE_SCANNERS } from '../../constants';
import { OPTIONS } from './ci_variable_constants';

export default {
  i18n: {
    keyLabel: s__('ScanExecutionPolicy|Key'),
    valueLabel: s__('ScanExecutionPolicy|Value'),
  },
  components: {
    GlCollapsibleListbox,
    GlFormInput,
    GenericBaseLayoutComponent,
  },
  props: {
    scanType: {
      type: String,
      required: true,
    },
    selected: {
      type: Object,
      required: true,
    },
    variable: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    availableScanOptions() {
      const currentlySelectedVariables = Object.keys(this.selected);
      return this.scanOptions.filter(({ value }) => {
        return (
          value.toLowerCase().includes(this.searchTerm.toLowerCase()) &&
          !currentlySelectedVariables.includes(value)
        );
      });
    },
    scanOptions() {
      return OPTIONS[RULE_MODE_SCANNERS[this.scanType]]?.map((s) => ({ text: s, value: s })) || [];
    },
    toggleText() {
      return this.variable || s__('ScanExecutionPolicy|Select a variable');
    },
  },
  created() {
    if (this.variable && !OPTIONS[RULE_MODE_SCANNERS[this.scanType]].includes(this.variable)) {
      this.$emit('error');
    }
  },
  methods: {
    handleSearch(value) {
      this.searchTerm = value;
    },
    selectVariable(variable) {
      this.$emit('input', [variable, this.value]);
    },
    removeVariable() {
      this.$emit('remove', this.variable);
    },
    updateValue(value) {
      this.$emit('input', [this.variable, value]);
    },
  },
};
</script>

<template>
  <generic-base-layout-component
    class="gl-w-full gl-bg-white gl-pt-0 gl-px-0 gl-pb-2"
    content-classes="gl-justify-content-space-between"
    @remove="removeVariable"
  >
    <template #selector>
      <div class="gl-flex-grow-2 gl-w-30p gl-display-flex gl-align-items-center">
        <label class="gl-mb-0 gl-mr-3" :title="$options.i18n.keyLabel">
          {{ $options.i18n.keyLabel }}
        </label>
        <gl-collapsible-listbox
          fluid-width
          searchable
          toggle-class="gl-display-grid"
          :items="availableScanOptions"
          :selected="variable"
          :toggle-text="toggleText"
          @search="handleSearch"
          @select="selectVariable"
        />
      </div>
    </template>
    <template #content>
      <div class="gl-flex-grow-1 gl-display-flex gl-align-items-center">
        <label class="gl-mb-0 gl-mr-3" :title="$options.i18n.valueLabel">
          {{ $options.i18n.valueLabel }}
        </label>
        <gl-form-input :value="value" @input="updateValue" />
      </div>
    </template>
  </generic-base-layout-component>
</template>
