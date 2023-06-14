<script>
import { GlFormGroup, GlFormInputGroup } from '@gitlab/ui';
import { INSTANCE_TYPE, RUNNER_TYPES } from '~/ci/runner/constants';

export default {
  components: {
    GlFormGroup,
    GlFormInputGroup,
  },
  props: {
    runnerType: {
      type: String,
      required: false,
      default: null,
      validator: (t) => RUNNER_TYPES.includes(t),
    },
    value: {
      required: false,
      type: Object,
      default: null,
    },
  },
  computed: {
    isSaasRunner() {
      // Using dot_com is discouraged but no clear alternative
      // is available. These fields should be available in any
      // SaaS setup.
      // https://gitlab.com/gitlab-org/gitlab/-/issues/225101
      return this.runnerType === INSTANCE_TYPE && gon?.dot_com;
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
  <div v-if="isSaasRunner && value">
    <gl-form-group
      label-for="runner-public-projects-minutes-cost-factor"
      data-testid="runner-field-public-projects-cost-factor"
      :label="__('Public projects compute cost factor')"
    >
      <gl-form-input-group
        id="runner-public-projects-minutes-cost-factor"
        :value="value.publicProjectsMinutesCostFactor"
        type="number"
        step="any"
        @input="onInputPublicProjectMinutesCostFactor"
      />
    </gl-form-group>

    <gl-form-group
      label-for="runner-private-projects-minutes-cost-factor"
      data-testid="runner-field-private-projects-cost-factor"
      :label="__('Private projects compute cost factor')"
    >
      <gl-form-input-group
        id="runner-private-projects-minutes-cost-factor"
        :value="value.privateProjectsMinutesCostFactor"
        type="number"
        step="any"
        @input="onInputPrivateProjectMinutesCostFactor"
      />
    </gl-form-group>
  </div>
</template>
