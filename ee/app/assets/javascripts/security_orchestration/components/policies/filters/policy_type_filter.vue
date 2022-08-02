<script>
import { GlFormGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import { POLICY_TYPE_FILTER_OPTIONS } from '../constants';

export default {
  name: 'PolicyTypeFilter',
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
        Object.values(POLICY_TYPE_FILTER_OPTIONS)
          .map((option) => option.value)
          .includes(value),
    },
  },
  computed: {
    selectedValueText() {
      return Object.values(POLICY_TYPE_FILTER_OPTIONS).find(({ value }) => value === this.value)
        .text;
    },
  },
  methods: {
    setPolicyType({ value }) {
      this.$emit('input', value);
    },
  },
  policyTypeFilterId: 'policy-type-filter',
  POLICY_TYPE_FILTER_OPTIONS,
  i18n: {
    label: __('Type'),
  },
};
</script>

<template>
  <gl-form-group
    :label="$options.i18n.label"
    label-size="sm"
    :label-for="$options.policyTypeFilterId"
  >
    <gl-dropdown
      :id="$options.policyTypeFilterId"
      class="gl-display-flex"
      toggle-class="gl-truncate"
      :text="selectedValueText"
    >
      <gl-dropdown-item
        v-for="option in $options.POLICY_TYPE_FILTER_OPTIONS"
        :key="option.value"
        :data-testid="`policy-type-${option.value}-option`"
        @click="setPolicyType(option)"
      >
        {{ option.text }}
      </gl-dropdown-item>
    </gl-dropdown>
  </gl-form-group>
</template>
