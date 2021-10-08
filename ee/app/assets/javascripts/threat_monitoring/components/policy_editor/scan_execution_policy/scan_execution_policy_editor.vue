<script>
import { GlEmptyState } from '@gitlab/ui';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import { EDITOR_MODES, EDITOR_MODE_YAML } from '../constants';
import PolicyEditorLayout from '../policy_editor_layout.vue';
import {
  DEFAULT_SCAN_EXECUTION_POLICY,
  fromYaml,
  GRAPHQL_ERROR_MESSAGE,
  modifyPolicy,
  SECURITY_POLICY_ACTIONS,
  toYaml,
} from './lib';

export default {
  SECURITY_POLICY_ACTIONS,
  DEFAULT_EDITOR_MODE: EDITOR_MODE_YAML,
  EDITOR_MODES: [EDITOR_MODES[1]],
  i18n: {
    createMergeRequest: __('Create merge request'),
    notOwnerButtonText: __('Learn more'),
    notOwnerDescription: s__(
      'SecurityOrchestration|Scan execution policies can only be created by project owners.',
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
      : DEFAULT_SCAN_EXECUTION_POLICY;

    return {
      error: '',
      isCreatingMR: false,
      isRemovingPolicy: false,
      policy: fromYaml(yamlEditorValue),
      yamlEditorValue,
    };
  },
  computed: {
    originalName() {
      return this.existingPolicy?.name;
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
    async handleModifyPolicy(act) {
      const action =
        act ||
        (this.isEditing
          ? this.$options.SECURITY_POLICY_ACTIONS.REPLACE
          : this.$options.SECURITY_POLICY_ACTIONS.APPEND);

      this.$emit('error', '');
      this.setLoadingFlag(action, true);

      try {
        const { mergeRequest, policyProject } = await modifyPolicy({
          action,
          assignedPolicyProject: this.assignedPolicyProject,
          name: this.originalName || fromYaml(this.yamlEditorValue)?.name,
          projectPath: this.projectPath,
          yamlEditorValue: this.yamlEditorValue,
        });

        this.redirectToMergeRequest({ mergeRequest, policyProject });
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
    redirectToMergeRequest({ mergeRequest, policyProject }) {
      visitUrl(
        joinPaths(
          gon.relative_url_root || '/',
          policyProject.fullPath,
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
