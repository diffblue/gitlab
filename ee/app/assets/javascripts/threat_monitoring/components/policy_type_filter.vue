<script>
import { GlFormGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { POLICY_TYPE_OPTIONS } from './constants';

export default {
  name: 'PolicyTypeFilter',
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    value: {
      type: String,
      required: true,
      validator: (value) =>
        Object.values(POLICY_TYPE_OPTIONS)
          .map((option) => option.value)
          .includes(value),
    },
  },
  computed: {
    selectedValueText() {
      return Object.values(POLICY_TYPE_OPTIONS).find(({ value }) => value === this.value).text;
    },
    isScanResultPolicyEnabled() {
      return this.glFeatures.scanResultPolicy;
    },
    policyTypeOptions() {
      const policyType = POLICY_TYPE_OPTIONS;
      if (!this.isScanResultPolicyEnabled) {
        delete policyType.POLICY_TYPE_SCAN_RESULT;
      }
      return policyType;
    },
  },
  methods: {
    setPolicyType({ value }) {
      this.$emit('input', value);
    },
  },
  policyTypeFilterId: 'policy-type-filter',
  POLICY_TYPE_OPTIONS,
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
        v-for="option in policyTypeOptions"
        :key="option.value"
        :data-testid="`policy-type-${option.value}-option`"
        @click="setPolicyType(option)"
        >{{ option.text }}</gl-dropdown-item
      >
    </gl-dropdown>
  </gl-form-group>
</template>
