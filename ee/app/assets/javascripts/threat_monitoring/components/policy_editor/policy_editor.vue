<script>
import { GlAlert, GlFormGroup, GlFormSelect } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
  mixins: [glFeatureFlagMixin()],
  inject: ['policyType'],
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
  },
  data() {
    return {
      error: '',
      errorMessages: [],
      newPolicyType: POLICY_TYPE_COMPONENT_OPTIONS.container.value,
    };
  },
  computed: {
    currentPolicyType() {
      return this.isEditing ? this.policyType : this.newPolicyType;
    },
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
      const types = Object.values(POLICY_TYPE_COMPONENT_OPTIONS);

      return this.isScanResultPolicyEnabled
        ? types
        : types.filter((type) => type.value !== POLICY_TYPE_COMPONENT_OPTIONS.scanResult?.value);
    },
    policyOptions() {
      return (
        this.policyTypes.find((option) => {
          return this.isEditing
            ? option.urlParameter === this.currentPolicyType
            : option.value === this.currentPolicyType;
        }) || POLICY_TYPE_COMPONENT_OPTIONS.container
      );
    },
    shouldAllowPolicyTypeSelection() {
      return !this.existingPolicy;
    },
    isScanResultPolicyEnabled() {
      return this.glFeatures.scanResultPolicy;
    },
  },
  methods: {
    setError(errors) {
      [this.error, ...this.errorMessages] = errors.split('\n');
    },
    handleNewPolicyType(type) {
      this.newPolicyType = type;
    },
  },
  i18n: {
    title: s__('SecurityOrchestration|Policy description'),
  },
};
</script>

<template>
  <section class="policy-editor">
    <gl-alert
      v-if="error"
      :title="error"
      dissmissable="true"
      variant="danger"
      @dismiss="setError('')"
    >
      <ul v-if="errorMessages.length" class="gl-mb-0! gl-ml-5">
        <li v-for="errorMessage in errorMessages" :key="errorMessage">
          {{ errorMessage }}
        </li>
      </ul>
    </gl-alert>
    <header class="gl-pb-5">
      <h3>{{ $options.i18n.title }}</h3>
    </header>
    <div class="gl-display-flex">
      <gl-form-group :label="s__('SecurityOrchestration|Policy type')" label-for="policyType">
        <gl-form-select
          id="policyType"
          data-qa-selector="policy_type_form_select"
          :value="policyOptions.value"
          :options="policyTypes"
          :disabled="!shouldAllowPolicyTypeSelection"
          @change="handleNewPolicyType"
        />
      </gl-form-group>
      <environment-picker v-if="policyOptions.shouldShowEnvironmentPicker" class="gl-ml-5" />
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
