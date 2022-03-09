<script>
import {
  GlEmptyState,
  GlButton,
  GlToggle,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlAlert,
} from '@gitlab/ui';
import { joinPaths, visitUrl, setUrlFragment } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import {
  EDITOR_MODE_YAML,
  EDITOR_MODE_RULE,
  SECURITY_POLICY_ACTIONS,
  GRAPHQL_ERROR_MESSAGE,
  PARSING_ERROR_MESSAGE,
} from '../constants';
import PolicyEditorLayout from '../policy_editor_layout.vue';
import { assignSecurityPolicyProject, modifyPolicy } from '../utils';
import DimDisableContainer from '../dim_disable_container.vue';
import PolicyActionBuilder from './policy_action_builder.vue';
import PolicyRuleBuilder from './policy_rule_builder.vue';
import { DEFAULT_SCAN_RESULT_POLICY, fromYaml, toYaml, buildRule } from './lib';

export default {
  SECURITY_POLICY_ACTIONS,
  EDITOR_MODE_YAML,
  EDITOR_MODE_RULE,
  SHARED_FOR_DISABLED:
    'gl-bg-gray-10 gl-border-solid gl-border-1 gl-border-gray-100 gl-rounded-base',
  i18n: {
    PARSING_ERROR_MESSAGE,
    addRule: s__('SecurityOrchestration|Add rule'),
    description: __('Description'),
    name: __('Name'),
    toggleLabel: s__('SecurityOrchestration|Policy status'),
    rules: s__('SecurityOrchestration|Rules'),
    createMergeRequest: __('Create via merge request'),
    notOwnerButtonText: __('Learn more'),
    notOwnerDescription: s__(
      'SecurityOrchestration|Scan result policies can only be created by project owners.',
    ),
    yamlPreview: s__('SecurityOrchestration|.yaml preview'),
    actions: s__('SecurityOrchestration|Actions'),
  },
  components: {
    GlEmptyState,
    GlButton,
    GlToggle,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlAlert,
    PolicyActionBuilder,
    PolicyRuleBuilder,
    PolicyEditorLayout,
    DimDisableContainer,
  },
  inject: [
    'disableScanPolicyUpdate',
    'policyEditorEmptyStateSvgPath',
    'projectId',
    'projectPath',
    'scanPolicyDocumentationPath',
    'scanResultPolicyApprovers',
  ],
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
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    const yamlEditorValue = this.existingPolicy
      ? toYaml(this.existingPolicy)
      : DEFAULT_SCAN_RESULT_POLICY;

    return {
      error: '',
      isCreatingMR: false,
      isRemovingPolicy: false,
      newlyCreatedPolicyProject: null,
      policy: fromYaml(yamlEditorValue),
      yamlEditorValue,
      documentationPath: setUrlFragment(
        this.scanPolicyDocumentationPath,
        'scan-result-policy-editor',
      ),
      yamlEditorError: null,
      mode: EDITOR_MODE_RULE,
    };
  },
  computed: {
    originalName() {
      return this.existingPolicy?.name;
    },
    policyActionName() {
      return this.isEditing
        ? this.$options.SECURITY_POLICY_ACTIONS.REPLACE
        : this.$options.SECURITY_POLICY_ACTIONS.APPEND;
    },
    policyYaml() {
      return this.hasParsingError ? '' : toYaml(this.policy);
    },
    hasParsingError() {
      return Boolean(this.yamlEditorError);
    },
    isWithinLimit() {
      return this.policy.rules.length < 5;
    },
  },
  methods: {
    updateAction(actionIndex, values) {
      this.policy.actions.splice(actionIndex, 1, values);
    },
    addRule() {
      this.policy.rules.push(buildRule());
    },
    removeRule(ruleIndex) {
      this.policy.rules.splice(ruleIndex, 1);
    },
    updateRule(ruleIndex, values) {
      this.policy.rules.splice(ruleIndex, 1, values);
    },
    handleError(error) {
      if (error.message.toLowerCase().includes('graphql')) {
        this.$emit('error', GRAPHQL_ERROR_MESSAGE);
      } else {
        this.$emit('error', error.message);
      }
    },
    async getSecurityPolicyProject() {
      if (!this.newlyCreatedPolicyProject && !this.assignedPolicyProject.fullPath) {
        this.newlyCreatedPolicyProject = await assignSecurityPolicyProject(this.projectPath);
      }

      return this.newlyCreatedPolicyProject || this.assignedPolicyProject;
    },
    async handleModifyPolicy(act) {
      const action = act || this.policyActionName;

      this.$emit('error', '');
      this.setLoadingFlag(action, true);

      try {
        const assignedPolicyProject = await this.getSecurityPolicyProject();
        const yamlValue =
          this.mode === EDITOR_MODE_YAML ? this.yamlEditorValue : toYaml(this.policy);
        const mergeRequest = await modifyPolicy({
          action,
          assignedPolicyProject,
          name: this.originalName || fromYaml(yamlValue)?.name,
          projectPath: this.projectPath,
          yamlEditorValue: yamlValue,
        });

        this.redirectToMergeRequest({ mergeRequest, assignedPolicyProject });
      } catch (e) {
        this.handleError(e);
        this.setLoadingFlag(action, false);
      }
    },
    setLoadingFlag(action, val) {
      if (action === SECURITY_POLICY_ACTIONS.REMOVE) {
        this.isRemovingPolicy = val;
      } else {
        this.isCreatingMR = val;
      }
    },
    redirectToMergeRequest({ mergeRequest, assignedPolicyProject }) {
      visitUrl(
        joinPaths(
          gon.relative_url_root || '/',
          assignedPolicyProject.fullPath,
          '/-/merge_requests',
          mergeRequest.id,
        ),
      );
    },
    updateYaml(manifest) {
      this.yamlEditorValue = manifest;
      this.yamlEditorError = null;

      try {
        const newPolicy = fromYaml(manifest);
        if (newPolicy.error) {
          throw new Error(newPolicy.error);
        }
        this.policy = { ...this.policy, ...newPolicy };
      } catch (error) {
        this.yamlEditorError = error;
      }
    },
    changeEditorMode(mode) {
      this.mode = mode;
      if (mode === EDITOR_MODE_YAML && !this.hasParsingError) {
        this.yamlEditorValue = toYaml(this.policy);
      }
    },
  },
};
</script>

<template>
  <policy-editor-layout
    v-if="!disableScanPolicyUpdate"
    :custom-save-button-text="$options.i18n.createMergeRequest"
    :is-editing="isEditing"
    :is-removing-policy="isRemovingPolicy"
    :is-updating-policy="isCreatingMR"
    :policy-name="policy.name"
    :yaml-editor-value="yamlEditorValue"
    @remove-policy="handleModifyPolicy($options.SECURITY_POLICY_ACTIONS.REMOVE)"
    @save-policy="handleModifyPolicy()"
    @update-yaml="updateYaml"
    @update-editor-mode="changeEditorMode"
  >
    <template #rule-editor>
      <gl-alert
        v-if="hasParsingError"
        data-testid="parsing-alert"
        class="gl-mb-5"
        :dismissible="false"
      >
        {{ $options.i18n.PARSING_ERROR_MESSAGE }}
      </gl-alert>

      <gl-form-group :label="$options.i18n.name" label-for="policyName">
        <gl-form-input id="policyName" v-model="policy.name" :disabled="hasParsingError" />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.description" label-for="policyDescription">
        <gl-form-textarea
          id="policyDescription"
          v-model="policy.description"
          :disabled="hasParsingError"
        />
      </gl-form-group>

      <gl-form-group :disabled="hasParsingError" data-testid="policy-enable">
        <gl-toggle
          v-model="policy.enabled"
          :label="$options.i18n.toggleLabel"
          :disabled="hasParsingError"
        />
      </gl-form-group>

      <dim-disable-container data-testid="rule-builder-container" :disabled="hasParsingError">
        <template #title>
          <h4>{{ $options.i18n.rules }}</h4>
        </template>

        <template #disabled>
          <div :class="`${$options.SHARED_FOR_DISABLED} gl-p-6`"></div>
        </template>

        <policy-rule-builder
          v-for="(rule, index) in policy.rules"
          :key="index"
          class="gl-mb-4"
          :init-rule="rule"
          @changed="updateRule(index, $event)"
          @remove="removeRule(index)"
        />

        <div v-if="isWithinLimit" :class="`${$options.SHARED_FOR_DISABLED} gl-p-5 gl-mb-5`">
          <gl-button variant="link" data-testid="add-rule" icon="plus" @click="addRule">
            {{ $options.i18n.addRule }}
          </gl-button>
        </div>
      </dim-disable-container>

      <dim-disable-container data-testid="action-container" :disabled="hasParsingError">
        <template #title>
          <h4>{{ $options.i18n.actions }}</h4>
        </template>

        <template #disabled>
          <div :class="`${$options.SHARED_FOR_DISABLED} gl-p-6`"></div>
        </template>

        <policy-action-builder
          v-for="(action, index) in policy.actions"
          :key="index"
          class="gl-mb-4"
          :init-action="action"
          :existing-approvers="scanResultPolicyApprovers"
          @changed="updateAction(index, $event)"
        />
      </dim-disable-container>
    </template>

    <template #rule-editor-preview>
      <h5>{{ $options.i18n.yamlPreview }}</h5>
      <pre
        data-testid="yaml-preview"
        class="gl-bg-white gl-border-none gl-p-0"
        :class="{ 'gl-opacity-5': hasParsingError }"
        >{{ policyYaml || yamlEditorValue }}</pre
      >
    </template>
  </policy-editor-layout>
  <gl-empty-state
    v-else
    :description="$options.i18n.notOwnerDescription"
    :primary-button-link="documentationPath"
    :primary-button-text="$options.i18n.notOwnerButtonText"
    :svg-path="policyEditorEmptyStateSvgPath"
    title=""
  />
</template>
