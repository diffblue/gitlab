<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { joinPaths, visitUrl, setUrlFragment } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import {
  EDITOR_MODE_RULE,
  EDITOR_MODE_YAML,
  GRAPHQL_ERROR_MESSAGE,
  PARSING_ERROR_MESSAGE,
  DAST_SCANNERS_PARSING_ERROR,
  RUNNER_TAGS_PARSING_ERROR,
  SECURITY_POLICY_ACTIONS,
  ACTIONS_LABEL,
  ADD_ACTION_LABEL,
} from '../constants';
import PolicyEditorLayout from '../policy_editor_layout.vue';
import DimDisableContainer from '../dim_disable_container.vue';
import { assignSecurityPolicyProject, modifyPolicy } from '../utils';
import PolicyRuleBuilder from './policy_rule_builder.vue';
import PolicyActionBuilder from './policy_action_builder.vue';
import {
  buildScannerAction,
  buildDefaultPipeLineRule,
  createPolicyObject,
  DEFAULT_SCAN_EXECUTION_POLICY,
  fromYaml,
  toYaml,
} from './lib';
import {
  DEFAULT_SCANNER,
  ADD_CONDITION_LABEL,
  CONDITIONS_LABEL,
  POLICY_ACTION_BUILDER_TAGS_ERROR_KEY,
} from './constants';

export default {
  ACTION: 'actions',
  RULE: 'rules',
  EDITOR_MODE_RULE,
  EDITOR_MODE_YAML,
  SECURITY_POLICY_ACTIONS,
  i18n: {
    ACTIONS_LABEL,
    ADD_ACTION_LABEL,
    ADD_CONDITION_LABEL,
    CONDITIONS_LABEL,
    PARSING_ERROR_MESSAGE,
    RUNNER_TAGS_PARSING_ERROR,
    DAST_SCANNERS_PARSING_ERROR,
    createMergeRequest: __('Configure with a merge request'),
    notOwnerButtonText: __('Learn more'),
    notOwnerDescription: s__(
      'SecurityOrchestration|Scan execution policies can only be created by project owners.',
    ),
  },
  components: {
    DimDisableContainer,
    GlButton,
    GlEmptyState,
    PolicyActionBuilder,
    PolicyEditorLayout,
    PolicyRuleBuilder,
  },
  inject: [
    'disableScanPolicyUpdate',
    'policyEditorEmptyStateSvgPath',
    'namespacePath',
    'scanPolicyDocumentationPath',
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
      : DEFAULT_SCAN_EXECUTION_POLICY;

    const { policy, hasParsingError } = createPolicyObject(yamlEditorValue);

    return {
      isCreatingMR: false,
      isRemovingPolicy: false,
      newlyCreatedPolicyProject: null,
      policy,
      hasParsingError,
      parsingError: this.$options.i18n.PARSING_ERROR_MESSAGE,
      yamlEditorValue,
      mode: EDITOR_MODE_RULE,
      documentationPath: setUrlFragment(
        this.scanPolicyDocumentationPath,
        'scan-execution-policy-editor',
      ),
    };
  },
  computed: {
    originalName() {
      return this.existingPolicy?.name;
    },
  },
  methods: {
    addAction() {
      this.policy.actions.push(buildScannerAction({ scanner: DEFAULT_SCANNER }));
      this.updateYamlEditorValue(this.policy);
    },
    addRule() {
      this.policy.rules.push(buildDefaultPipeLineRule());
      this.updateYamlEditorValue(this.policy);
    },
    removeActionOrRule(type, index) {
      this.policy[type].splice(index, 1);
      this.updateYamlEditorValue(this.policy);
    },
    updateActionOrRule(type, index, values) {
      this.policy[type].splice(index, 1, values);
      this.updateYamlEditorValue(this.policy);
    },
    changeEditorMode(mode) {
      this.mode = mode;
    },
    handleError(error) {
      if (error.message.toLowerCase().includes('graphql')) {
        this.$emit('error', GRAPHQL_ERROR_MESSAGE);
      } else {
        this.$emit('error', error.message);
      }
    },
    handleActionBuilderParsingError(key) {
      this.hasParsingError = true;
      this.parsingError =
        key === POLICY_ACTION_BUILDER_TAGS_ERROR_KEY
          ? this.$options.i18n.RUNNER_TAGS_PARSING_ERROR
          : this.$options.i18n.DAST_SCANNERS_PARSING_ERROR;
    },
    handleSetPolicyProperty(property, value) {
      this.policy[property] = value;
      this.updateYamlEditorValue(this.policy);
    },
    async getSecurityPolicyProject() {
      if (!this.newlyCreatedPolicyProject && !this.assignedPolicyProject.fullPath) {
        this.newlyCreatedPolicyProject = await assignSecurityPolicyProject(this.namespacePath);
      }

      return this.newlyCreatedPolicyProject || this.assignedPolicyProject;
    },
    async handleModifyPolicy(act) {
      const action =
        act ||
        (this.isEditing
          ? this.$options.SECURITY_POLICY_ACTIONS.REPLACE
          : this.$options.SECURITY_POLICY_ACTIONS.APPEND);

      this.$emit('error', '');
      this.setLoadingFlag(action, true);

      try {
        const assignedPolicyProject = await this.getSecurityPolicyProject();
        const mergeRequest = await modifyPolicy({
          action,
          assignedPolicyProject,
          name: this.originalName || fromYaml({ manifest: this.yamlEditorValue })?.name,
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
      const { policy, hasParsingError } = createPolicyObject(manifest);

      this.yamlEditorValue = manifest;
      this.hasParsingError = hasParsingError;
      this.parsingError = this.$options.i18n.PARSING_ERROR_MESSAGE;
      this.policy = policy;
    },
    updateYamlEditorValue(policy) {
      this.yamlEditorValue = toYaml(policy);
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
    :parsing-error="parsingError"
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
          <h4>{{ $options.i18n.CONDITIONS_LABEL }}</h4>
        </template>

        <template #disabled>
          <div class="gl-bg-gray-10 gl-rounded-base gl-p-6"></div>
        </template>

        <policy-rule-builder
          v-for="(rule, index) in policy.rules"
          :key="index"
          class="gl-mb-4"
          :init-rule="rule"
          :rule-index="index"
          @changed="updateActionOrRule($options.RULE, index, $event)"
          @remove="removeActionOrRule($options.RULE, index)"
        />

        <div class="gl-bg-gray-10 gl-rounded-base gl-p-5 gl-mb-5">
          <gl-button variant="link" data-testid="add-rule" icon="plus" @click="addRule">
            {{ $options.i18n.ADD_CONDITION_LABEL }}
          </gl-button>
        </div>
      </dim-disable-container>
    </template>

    <template #actions-first>
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
          :action-index="index"
          @changed="updateActionOrRule($options.ACTION, index, $event)"
          @remove="removeActionOrRule($options.ACTION, index)"
          @parsing-error="handleActionBuilderParsingError"
        />

        <div class="gl-bg-gray-10 gl-rounded-base gl-p-5 gl-mb-5">
          <gl-button variant="link" data-testid="add-action" icon="plus" @click="addAction">
            {{ $options.i18n.ADD_ACTION_LABEL }}
          </gl-button>
        </div>
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
