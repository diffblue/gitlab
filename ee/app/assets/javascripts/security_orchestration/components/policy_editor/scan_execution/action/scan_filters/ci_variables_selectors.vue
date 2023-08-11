<script>
import { isEmpty, uniqueId } from 'lodash';
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import GenericBaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/generic_base_layout_component.vue';
import { CI_VARIABLE } from './constants';
import CiVariableSelector from './ci_variable_selector.vue';

export default {
  i18n: {
    addLabel: s__('ScanExecutionPolicy|Add new CI variable'),
    label: s__('ScanExecutionPolicy|Customized CI variables:'),
    subLabel: s__(
      'ScanExecutionPolicy|Customized variables will overwrite ones defined in the project CI/CD file and settings',
    ),
    tooltipText: s__('ScanExecutionPolicy|Only one variable can be added at a time.'),
  },
  components: {
    GlButton,
    CiVariableSelector,
    GenericBaseLayoutComponent,
  },
  directives: { GlTooltip: GlTooltipDirective },
  props: {
    scanType: {
      type: String,
      required: true,
    },
    selected: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      variableTracker: Object.entries(this.selected).map(() => uniqueId()),
    };
  },
  computed: {
    hasEmptyVariable() {
      return this.variables.some(([key]) => key === '');
    },
    variables() {
      return Object.entries(this.selected).length ? Object.entries(this.selected) : [['', '']];
    },
  },
  methods: {
    addVariable() {
      this.variableTracker.push(uniqueId());
      this.$emit('input', { variables: { ...this.selected, '': '' } });
    },
    reduceVariablesToObject(array) {
      return array.reduce((acc, [key, value]) => {
        acc[key] = value;
        return acc;
      }, {});
    },
    remove() {
      this.$emit('remove', CI_VARIABLE);
    },
    removeVariable(variable, index) {
      this.variableTracker.splice(index, 1);
      const remainingVariables = this.variables.filter(([key]) => variable !== key);

      const variablesObject = this.reduceVariablesToObject(remainingVariables);
      if (isEmpty(variablesObject)) {
        this.remove();
      } else {
        this.$emit('input', { variables: variablesObject });
      }
    },
    updateVariable([key, value], index) {
      const newVariables = [...this.variables];
      newVariables[index] = [key, value];

      const variablesObject = this.reduceVariablesToObject(newVariables);
      this.$emit('input', { variables: variablesObject });
    },
  },
};
</script>

<template>
  <generic-base-layout-component @remove="remove">
    <template #selector>
      <label class="gl-mb-0" :title="$options.i18n.label">
        {{ $options.i18n.label }}
      </label>
      <p class="gl-mb-0">{{ $options.i18n.subLabel }}</p>
      <ci-variable-selector
        v-for="([key, value], index) in variables"
        :key="variableTracker[index]"
        :variable="key"
        :value="value"
        :scan-type="scanType"
        :selected="selected"
        @input="updateVariable($event, index)"
        @remove="removeVariable($event, index)"
      />
      <span v-gl-tooltip.hover="$options.i18n.tooltipText">
        <gl-button
          :disabled="hasEmptyVariable"
          variant="link"
          :aria-label="$options.i18n.addLabel"
          class="gl-pt-2 gl-mr-3"
          @click="addVariable"
        >
          {{ $options.i18n.addLabel }}
        </gl-button>
      </span>
    </template>
  </generic-base-layout-component>
</template>
