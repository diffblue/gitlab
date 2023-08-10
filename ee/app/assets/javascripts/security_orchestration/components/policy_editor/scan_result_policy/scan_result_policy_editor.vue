<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { joinPaths, visitUrl, setUrlFragment } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import {
  BRANCHES_KEY,
  EDITOR_MODE_YAML,
  EDITOR_MODE_RULE,
  SECURITY_POLICY_ACTIONS,
  GRAPHQL_ERROR_MESSAGE,
  PARSING_ERROR_MESSAGE,
  ACTIONS_LABEL,
  ADD_RULE_LABEL,
  RULES_LABEL,
  MAX_ALLOWED_RULES_LENGTH,
} from '../constants';
import PolicyEditorLayout from '../policy_editor_layout.vue';
import { assignSecurityPolicyProject, modifyPolicy } from '../utils';
import DimDisableContainer from '../dim_disable_container.vue';
import ApprovalSettings from './approval_settings.vue';
import PolicyActionBuilder from './policy_action_builder.vue';
import PolicyRuleBuilder from './policy_rule_builder.vue';

import {
  createPolicyObject,
  DEFAULT_SCAN_RESULT_POLICY,
  SCAN_RESULT_POLICY_SETTINGS_POLICY,
  getInvalidBranches,
  fromYaml,
  toYaml,
  approversOutOfSync,
  emptyBuildRule,
  invalidScanners,
  invalidVulnerabilitiesAllowed,
  invalidVulnerabilityStates,
  invalidVulnerabilityAge,
  humanizeInvalidBranchesError,
  invalidBranchType,
} from './lib';

export default {
  ADD_RULE_LABEL,
  RULES_LABEL,
  SECURITY_POLICY_ACTIONS,
  EDITOR_MODE_YAML,
  EDITOR_MODE_RULE,
  i18n: {
    PARSING_ERROR_MESSAGE,
    createMergeRequest: __('Configure with a merge request'),
    notOwnerButtonText: __('Learn more'),
    notOwnerDescription: s__(
      'SecurityOrchestration|Scan result policies can only be created by project owners.',
    ),
    settingsTitle: s__('ScanResultPolicy|Override project approval settings'),
    yamlPreview: s__('SecurityOrchestration|.yaml preview'),
    ACTIONS_LABEL,
  },
  components: {
    ApprovalSettings,
    DimDisableContainer,
    GlButton,
    GlEmptyState,
    PolicyActionBuilder,
    PolicyEditorLayout,
    PolicyRuleBuilder,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: [
    'disableScanPolicyUpdate',
    'policyEditorEmptyStateSvgPath',
    'namespaceId',
    'namespacePath',
    'scanPolicyDocumentationPath',
    'scanResultPolicyApprovers',
    'namespaceType',
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
    const DEFAULT_POLICY = this.glFeatures.scanResultPolicySettings
      ? SCAN_RESULT_POLICY_SETTINGS_POLICY
      : DEFAULT_SCAN_RESULT_POLICY;

    const yamlEditorValue = this.existingPolicy ? toYaml(this.existingPolicy) : DEFAULT_POLICY;

    const { policy, hasParsingError } = createPolicyObject(yamlEditorValue, this.glFeatures);

    return {
      errors: { action: [] },
      invalidBranches: [],
      isCreatingMR: false,
      isRemovingPolicy: false,
      newlyCreatedPolicyProject: null,
      policy,
      hasParsingError,
      documentationPath: setUrlFragment(
        this.scanPolicyDocumentationPath,
        'scan-result-policy-editor',
      ),
      mode: EDITOR_MODE_RULE,
      existingApprovers: this.scanResultPolicyApprovers,
      yamlEditorValue,
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
    isWithinLimit() {
      return this.policy.rules?.length < MAX_ALLOWED_RULES_LENGTH;
    },
    hasEmptyRules() {
      return this.policy.rules?.length === 0 || this.policy.rules?.at(0)?.type === '';
    },
    isActiveRuleMode() {
      return this.mode === EDITOR_MODE_RULE && !this.hasParsingError;
    },
    allBranches() {
      return this.policy.rules.flatMap((rule) => rule.branches);
    },
    rulesHaveBranches() {
      return this.policy.rules.some(this.ruleHasBranchesProperty);
    },
    shouldShowSettings() {
      return this.glFeatures.scanResultPolicySettings;
    },
  },
  watch: {
    invalidBranches(branches) {
      if (branches.length > 0) {
        this.handleError(new Error(humanizeInvalidBranchesError([...branches])));
      } else {
        this.$emit('error', '');
      }
    },
  },
  methods: {
    ruleHasBranchesProperty(rule) {
      return BRANCHES_KEY in rule;
    },
    updateAction(actionIndex, values) {
      this.policy.actions.splice(actionIndex, 1, values);
      this.$set(this.errors, 'action', []);
      this.updateYamlEditorValue(this.policy);
    },
    updateApprovalSettings(values) {
      this.policy.approval_settings = values;
      this.updateYamlEditorValue(this.policy);
    },
    addRule() {
      this.policy.rules.push(emptyBuildRule());
      this.updateYamlEditorValue(this.policy);
    },
    removeRule(ruleIndex) {
      this.policy.rules.splice(ruleIndex, 1);
      this.updateYamlEditorValue(this.policy);
    },
    updateRule(ruleIndex, values) {
      this.policy.rules.splice(ruleIndex, 1, values);
      this.updateYamlEditorValue(this.policy);
    },
    handleError(error) {
      if (this.isActiveRuleMode && error.cause?.length) {
        const updatedErrors = error.cause.reduce(
          (acc, cause) => {
            switch (cause.field) {
              case 'approver_ids':
              default:
                acc.action.push(cause);
            }
            return acc;
          },
          { action: [] },
        );
        this.errors = updatedErrors;
      } else if (error.message.toLowerCase().includes('graphql')) {
        this.$emit('error', GRAPHQL_ERROR_MESSAGE);
      } else {
        this.$emit('error', error.message);
      }
    },
    handleParsingError() {
      this.hasParsingError = true;
    },
    async getSecurityPolicyProject() {
      if (!this.newlyCreatedPolicyProject && !this.assignedPolicyProject.fullPath) {
        this.newlyCreatedPolicyProject = await assignSecurityPolicyProject(this.namespacePath);
      }

      return this.newlyCreatedPolicyProject || this.assignedPolicyProject;
    },
    async handleModifyPolicy(act) {
      const action = act || this.policyActionName;

      this.$emit('error', '');
      this.setLoadingFlag(action, true);

      try {
        const assignedPolicyProject = await this.getSecurityPolicyProject();
        const mergeRequest = await modifyPolicy({
          action,
          assignedPolicyProject,
          name:
            this.originalName ||
            fromYaml({ manifest: this.yamlEditorValue, glFeatures: this.glFeatures })?.name,
          namespacePath: this.namespacePath,
          yamlEditorValue: this.yamlEditorValue,
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
    handleSetPolicyProperty(property, value) {
      this.policy[property] = value;
      this.updateYamlEditorValue(this.policy);
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
      const { policy, hasParsingError } = createPolicyObject(manifest, this.glFeatures);

      this.yamlEditorValue = manifest;
      this.hasParsingError = hasParsingError;
      this.policy = policy;
    },
    updateYamlEditorValue(policy) {
      this.yamlEditorValue = toYaml(policy);
    },
    async changeEditorMode(mode) {
      this.mode = mode;
      if (this.isActiveRuleMode) {
        this.hasParsingError = this.invalidForRuleMode();

        if (
          !this.hasEmptyRules &&
          this.namespaceType === NAMESPACE_TYPES.PROJECT &&
          this.rulesHaveBranches
        ) {
          this.invalidBranches = await getInvalidBranches({
            branches: this.allBranches,
            projectId: this.namespaceId,
          });
        }
      }
    },
    updatePolicyApprovers(values) {
      this.existingApprovers = values;
    },
    invalidForRuleMode() {
      const invalidApprovers = approversOutOfSync(this.policy.actions[0], this.existingApprovers);
      const { rules } = this.policy;

      return (
        invalidApprovers ||
        invalidScanners(rules) ||
        invalidVulnerabilitiesAllowed(rules) ||
        invalidVulnerabilityStates(rules) ||
        invalidBranchType(rules) ||
        invalidVulnerabilityAge(rules)
      );
    },
  },
};
</script>

<template>
  <policy-editor-layout
    v-if="!disableScanPolicyUpdate"
    :custom-save-button-text="$options.i18n.createMergeRequest"
    :has-parsing-error="hasParsingError"
    :is-editing="isEditing"
    :is-removing-policy="isRemovingPolicy"
    :is-updating-policy="isCreatingMR"
    :parsing-error="$options.i18n.PARSING_ERROR_MESSAGE"
    :policy="policy"
    :yaml-editor-value="yamlEditorValue"
    @remove-policy="handleModifyPolicy($options.SECURITY_POLICY_ACTIONS.REMOVE)"
    @save-policy="handleModifyPolicy()"
    @set-policy-property="handleSetPolicyProperty"
    @update-yaml="updateYaml"
    @update-editor-mode="changeEditorMode"
  >
    <template #rules>
      <dim-disable-container data-testid="rule-builder-container" :disabled="hasParsingError">
        <template #title>
          <h4>{{ $options.RULES_LABEL }}</h4>
        </template>

        <template #disabled>
          <div class="gl-bg-gray-10 gl-rounded-base gl-p-6"></div>
        </template>

        <policy-rule-builder
          v-for="(rule, index) in policy.rules"
          :key="index"
          class="gl-mb-4"
          :init-rule="rule"
          @changed="updateRule(index, $event)"
          @remove="removeRule(index)"
        />

        <div
          v-if="isWithinLimit"
          class="security-policies-bg-gray-10 gl-rounded-base gl-p-5 gl-mb-5"
        >
          <gl-button variant="link" data-testid="add-rule" icon="plus" @click="addRule">
            {{ $options.ADD_RULE_LABEL }}
          </gl-button>
        </div>
      </dim-disable-container>
    </template>
    <template #actions>
      <dim-disable-container data-testid="action-container" :disabled="hasParsingError">
        <template #title>
          <h4>{{ $options.i18n.ACTIONS_LABEL }}</h4>
        </template>

        <template #disabled>
          <div class="gl-bg-gray-10 gl-rounded-base gl-p-6"></div>
        </template>

        <policy-action-builder
          v-for="(action, index) in policy.actions"
          :key="index"
          class="gl-mb-4"
          :init-action="action"
          :errors="errors.action"
          :existing-approvers="existingApprovers"
          @error="handleParsingError"
          @updateApprovers="updatePolicyApprovers"
          @changed="updateAction(index, $event)"
        />
      </dim-disable-container>
    </template>
    <template #settings>
      <dim-disable-container v-if="shouldShowSettings" :disabled="hasParsingError">
        <template #title>
          <h5>{{ $options.i18n.settingsTitle }}</h5>
        </template>

        <template #disabled>
          <div class="gl-bg-gray-10 gl-rounded-base gl-p-6"></div>
        </template>

        <approval-settings
          :approval-settings="policy.approval_settings"
          @changed="updateApprovalSettings"
        />
      </dim-disable-container>
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
