<script>
import { GlFormGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import { POLICY_SOURCE_OPTIONS } from '../constants';

const POLICY_SOURCE_OPTIONS_VALUES = Object.values(POLICY_SOURCE_OPTIONS);

export default {
  name: 'PolicySourceFilter',
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    value: {
      type: String,
      required: true,
      validator: (value) =>
        POLICY_SOURCE_OPTIONS_VALUES.map((option) => option.value).includes(value),
    },
  },
  computed: {
    selectedValueText() {
      return POLICY_SOURCE_OPTIONS_VALUES.find(({ value }) => value === this.value).text;
    },
  },
  methods: {
    setPolicySource({ value }) {
      this.$emit('input', value);
    },
  },
  policySourceFilterId: 'policy-source-filter',
  POLICY_SOURCE_OPTIONS,
  i18n: {
    label: s__('SecurityOrchestration|Source'),
  },
};
</script>

<template>
  <gl-form-group
    :label="$options.i18n.label"
    label-size="sm"
    :label-for="$options.policySourceFilterId"
  >
    <gl-dropdown
      :id="$options.policySourceFilterId"
      class="gl-display-flex"
      toggle-class="gl-truncate"
      :text="selectedValueText"
    >
      <gl-dropdown-item
        v-for="option in $options.POLICY_SOURCE_OPTIONS"
        :key="option.value"
        :data-testid="`policy-source-${option.value}-option`"
        @click="setPolicySource(option)"
      >
        {{ option.text }}
      </gl-dropdown-item>
    </gl-dropdown>
  </gl-form-group>
</template>
