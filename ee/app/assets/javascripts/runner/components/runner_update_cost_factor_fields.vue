<script>
import { GlFormGroup, GlFormInputGroup } from '@gitlab/ui';

export default {
  components: {
    GlFormGroup,
    GlFormInputGroup,
  },
  props: {
    value: {
      required: false,
      type: Object,
      default: null,
    },
  },
  computed: {
    isSaas() {
      // Using dot_com is discouraged but no clear alternative
      // is available. These fields should be available in any
      // SaaS setup.
      // https://gitlab.com/gitlab-org/gitlab/-/issues/225101
      return gon?.dot_com;
    },
  },
  methods: {
    parseNumber(val) {
      const n = parseFloat(val);
      return Number.isNaN(n) ? val : n;
    },
    onInputPublicProjectMinutesCostFactor(val) {
      this.$emit('input', {
        ...this.value,
        publicProjectsMinutesCostFactor: this.parseNumber(val),
      });
    },
    onInputPrivateProjectMinutesCostFactor(val) {
      this.$emit('input', {
        ...this.value,
        privateProjectsMinutesCostFactor: this.parseNumber(val),
      });
    },
  },
};
</script>
<template>
  <div v-if="isSaas && value">
    <gl-form-group
      data-testid="runner-field-public-projects-cost-factor"
      :label="__('Public projects Minutes cost factor')"
    >
      <gl-form-input-group
        :value="value.publicProjectsMinutesCostFactor"
        type="number"
        step="any"
        @input="onInputPublicProjectMinutesCostFactor"
      />
    </gl-form-group>

    <gl-form-group
      data-testid="runner-field-private-projects-cost-factor"
      :label="__('Private projects Minutes cost factor')"
    >
      <gl-form-input-group
        :value="value.privateProjectsMinutesCostFactor"
        type="number"
        step="any"
        @input="onInputPrivateProjectMinutesCostFactor"
      />
    </gl-form-group>
  </div>
</template>
