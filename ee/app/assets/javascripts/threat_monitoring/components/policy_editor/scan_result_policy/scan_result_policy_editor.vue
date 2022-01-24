<script>
import { GlEmptyState } from '@gitlab/ui';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import {
  EDITOR_MODES,
  EDITOR_MODE_YAML,
  SECURITY_POLICY_ACTIONS,
  GRAPHQL_ERROR_MESSAGE,
} from '../constants';
import PolicyEditorLayout from '../policy_editor_layout.vue';
import { assignSecurityPolicyProject, modifyPolicy } from '../utils';
import { DEFAULT_SCAN_RESULT_POLICY, fromYaml, toYaml } from './lib';

export default {
  SECURITY_POLICY_ACTIONS,
  DEFAULT_EDITOR_MODE: EDITOR_MODE_YAML,
  EDITOR_MODES: [EDITOR_MODES[1]],
  i18n: {
    createMergeRequest: __('Create via merge request'),
    notOwnerButtonText: __('Learn more'),
    notOwnerDescription: s__(
      'SecurityOrchestration|Scan result policies can only be created by project owners.',
    ),
  },
  components: {
    GlEmptyState,
    PolicyEditorLayout,
  },
  inject: [
    'disableScanExecutionUpdate',
    'policyEditorEmptyStateSvgPath',
    'projectId',
    'projectPath',
    'scanExecutionDocumentationPath',
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
  },
  methods: {
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

        const mergeRequest = await modifyPolicy({
          action,
          assignedPolicyProject,
          name: this.originalName || fromYaml(this.yamlEditorValue)?.name,
          projectPath: this.projectPath,
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
      this.yamlEditorValue = manifest;
    },
  },
};
</script>

<template>
  <policy-editor-layout
    v-if="!disableScanExecutionUpdate"
    :custom-save-button-text="$options.i18n.createMergeRequest"
    :default-editor-mode="$options.DEFAULT_EDITOR_MODE"
    :editor-modes="$options.EDITOR_MODES"
    :is-editing="isEditing"
    :is-removing-policy="isRemovingPolicy"
    :is-updating-policy="isCreatingMR"
    :policy-name="policy.name"
    :yaml-editor-value="yamlEditorValue"
    @remove-policy="handleModifyPolicy($options.SECURITY_POLICY_ACTIONS.REMOVE)"
    @save-policy="handleModifyPolicy()"
    @update-yaml="updateYaml"
  />
  <gl-empty-state
    v-else
    :description="$options.i18n.notOwnerDescription"
    :primary-button-link="scanExecutionDocumentationPath"
    :primary-button-text="$options.i18n.notOwnerButtonText"
    :svg-path="policyEditorEmptyStateSvgPath"
    title=""
  />
</template>
