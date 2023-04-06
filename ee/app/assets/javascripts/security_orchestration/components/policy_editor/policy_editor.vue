<script>
import { GlAlert, GlFormGroup, GlFormSelect } from '@gitlab/ui';
import { s__ } from '~/locale';
import { NAMESPACE_TYPES } from '../../constants';
import { POLICY_TYPE_COMPONENT_OPTIONS } from '../constants';
import ScanExecutionPolicyEditor from './scan_execution_policy/scan_execution_policy_editor.vue';
import ScanResultPolicyEditor from './scan_result_policy/scan_result_policy_editor.vue';

export default {
  components: {
    GlAlert,
    GlFormGroup,
    GlFormSelect,
    ScanExecutionPolicyEditor,
    ScanResultPolicyEditor,
  },
  inject: {
    assignedPolicyProject: { default: null },
    existingPolicy: { default: null },
    namespaceType: { default: NAMESPACE_TYPES.PROJECT },
  },
  props: {
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
      return Boolean(this.existingPolicy);
    },
    policyTypes() {
      return Object.values(POLICY_TYPE_COMPONENT_OPTIONS);
    },
    policyOptions() {
      return (
        this.policyTypes.find(({ value }) => value === this.selectedPolicyType) ||
        POLICY_TYPE_COMPONENT_OPTIONS.scanExecution
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
  NAMESPACE_TYPES,
  i18n: {
    groupPolicyMessage: s__(
      'SecurityOrchestration|After enabling a group-level policy, this policy automatically applies to all projects and sub-groups in this group.',
    ),
  },
};
</script>

<template>
  <section class="policy-editor">
    <span
      v-if="namespaceType === $options.NAMESPACE_TYPES.GROUP"
      data-testid="group-level-notification"
    >
      {{ $options.i18n.groupPolicyMessage }}
    </span>
    <gl-alert
      v-if="error"
      class="gl-mt-5 security-policies-alert gl-z-index-2"
      :title="error"
      dismissible
      variant="danger"
      data-testid="error-alert"
      sticky
      @dismiss="setError('')"
    >
      <ul v-if="errorMessages.length" class="gl-mb-0! gl-ml-5">
        <li v-for="errorMessage in errorMessages" :key="errorMessage">
          {{ errorMessage }}
        </li>
      </ul>
    </gl-alert>
    <component
      :is="policyOptions.component"
      :existing-policy="existingPolicy"
      :assigned-policy-project="assignedPolicyProject"
      :is-editing="isEditing"
      @error="setError($event)"
    />
  </section>
</template>
