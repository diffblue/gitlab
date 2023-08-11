<script>
import { GlCollapsibleListbox, GlDropdownDivider, GlDropdownItem, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';
import GenericBaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/generic_base_layout_component.vue';
import { RULE_MODE_SCANNERS } from 'ee/security_orchestration/components/policy_editor/constants';
import { OPTIONS } from './ci_variable_constants';

export default {
  i18n: {
    createKeyLabel: s__('ScanExecutionPolicy|Use a custom key'),
    keyLabel: s__('ScanExecutionPolicy|Key'),
    selectLabel: s__('ScanExecutionPolicy|Select or Create a Key'),
    valueLabel: s__('ScanExecutionPolicy|Value'),
  },
  components: {
    GlCollapsibleListbox,
    GlDropdownDivider,
    GlDropdownItem,
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
    let customVariable = '';
    let isCustomVariable = false;
    if (this.variable && !OPTIONS[RULE_MODE_SCANNERS[this.scanType]].includes(this.variable)) {
      customVariable = this.variable;
      isCustomVariable = true;
    }

    return {
      customVariable,
      isCustomVariable,
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
      return this.variable || this.$options.i18n.selectLabel;
    },
  },
  methods: {
    handleSearch(value) {
      this.searchTerm = value;
    },
    handleFooterClick() {
      this.isCustomVariable = true;
      this.selectVariable('');
    },
    selectVariable(variable, isCustomVariable = false) {
      if (isCustomVariable) {
        this.customVariable = variable;
        this.isCustomVariable = isCustomVariable;
      }
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
          v-if="!isCustomVariable"
          fluid-width
          searchable
          toggle-class="gl-display-grid"
          :items="availableScanOptions"
          :selected="variable"
          :toggle-text="toggleText"
          @search="handleSearch"
          @select="selectVariable"
        >
          <template #footer>
            <gl-dropdown-divider />
            <gl-dropdown-item class="gl-list-style-none" @click="handleFooterClick">
              {{ $options.i18n.createKeyLabel }}
            </gl-dropdown-item>
          </template>
        </gl-collapsible-listbox>
        <gl-form-input
          v-else
          data-testid="custom-variable-input"
          :value="variable"
          @input="selectVariable($event, true)"
        />
      </div>
    </template>
    <template #content>
      <div class="gl-flex-grow-1 gl-display-flex gl-align-items-center">
        <label class="gl-mb-0 gl-mr-3" :title="$options.i18n.valueLabel">
          {{ $options.i18n.valueLabel }}
        </label>
        <gl-form-input :value="value" data-testid="value-input" @input="updateValue" />
      </div>
    </template>
  </generic-base-layout-component>
</template>
