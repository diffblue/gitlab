<script>
import { GlAlert, GlFormGroup, GlFormSelect } from '@gitlab/ui';
import { POLICY_TYPE_COMPONENT_OPTIONS } from '../constants';
import EnvironmentPicker from '../environment_picker.vue';
import NetworkPolicyEditor from './network_policy/network_policy_editor.vue';
import ScanExecutionPolicyEditor from './scan_execution_policy/scan_execution_policy_editor.vue';
import ScanResultPolicyEditor from './scan_result_policy/scan_result_policy_editor.vue';

export default {
  components: {
    GlAlert,
    GlFormGroup,
    GlFormSelect,
    EnvironmentPicker,
    NetworkPolicyEditor,
    ScanExecutionPolicyEditor,
    ScanResultPolicyEditor,
  },
  props: {
    assignedPolicyProject: {
      type: Object,
      required: true,
    },
    existingPolicy: {
      type: Object,
      required: false,
      default: null,
    },
    // This is the `value` field of the POLICY_TYPE_COMPONENT_OPTIONS
    selectedPolicyType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      error: '',
      errorMessages: [],
    };
  },
  computed: {
    isEditing() {
      if (!this.existingPolicy) {
        return false;
      }

      return Boolean(
        this.existingPolicy.creation_timestamp ||
          [
            POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.urlParameter,
            POLICY_TYPE_COMPONENT_OPTIONS.scanResult?.urlParameter,
          ].includes(this.existingPolicy.type),
      );
    },
    policyTypes() {
      return Object.values(POLICY_TYPE_COMPONENT_OPTIONS);
    },
    policyOptions() {
      return (
        this.policyTypes.find(({ value }) => value === this.selectedPolicyType) ||
        POLICY_TYPE_COMPONENT_OPTIONS.container
      );
    },
    shouldAllowPolicyTypeSelection() {
      return !this.existingPolicy;
    },
  },
  methods: {
    setError(errors) {
      [this.error, ...this.errorMessages] = errors.split('\n');
    },
  },
};
</script>

<template>
  <section class="policy-editor">
    <gl-alert v-if="error" :title="error" dismissible variant="danger" @dismiss="setError('')">
      <ul v-if="errorMessages.length" class="gl-mb-0! gl-ml-5">
        <li v-for="errorMessage in errorMessages" :key="errorMessage">
          {{ errorMessage }}
        </li>
      </ul>
    </gl-alert>
    <div class="gl-display-flex">
      <environment-picker v-if="policyOptions.shouldShowEnvironmentPicker" />
    </div>
    <component
      :is="policyOptions.component"
      :existing-policy="existingPolicy"
      :assigned-policy-project="assignedPolicyProject"
      :is-editing="isEditing"
      @error="setError($event)"
    />
  </section>
</template>
