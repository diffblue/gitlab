<script>
import { removeUnnecessaryDashes } from 'ee/threat_monitoring/utils';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { EDITOR_MODES, EDITOR_MODE_YAML } from '../constants';
import PolicyEditorLayout from '../policy_editor_layout.vue';
import {
  DEFAULT_SCAN_EXECUTION_POLICY,
  fromYaml,
  GRAPHQL_ERROR_MESSAGE,
  modifyPolicy,
} from './lib';

export default {
  ACTION_FLAGS: {
    APPEND: 'isCreatingMR',
    REMOVE: 'isRemovingPolicy',
    REPLACE: 'isCreatingMR',
  },
  DEFAULT_EDITOR_MODE: EDITOR_MODE_YAML,
  EDITOR_MODES: [EDITOR_MODES[1]],
  i18n: {
    createMergeRequest: __('Create merge request'),
  },
  components: {
    PolicyEditorLayout,
  },
  inject: ['disableScanExecutionUpdate', 'projectId', 'projectPath'],
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
    const yamlEditorValue = this.existingPolicy
      ? removeUnnecessaryDashes(this.existingPolicy.manifest)
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
    isEditing() {
      return Boolean(this.existingPolicy);
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
      const action = act || (this.isEditing ? 'REPLACE' : 'APPEND');

      this.$emit('error', '');
      this[this.$options.ACTION_FLAGS[action]] = true;

      try {
        const { mergeRequest, policyProject } = await modifyPolicy({
          action,
          assignedPolicyProject: this.assignedPolicyProject,
          projectPath: this.projectPath,
          yamlEditorValue: this.yamlEditorValue,
        });

        this.redirectToMergeRequest({ mergeRequest, policyProject });
      } catch (e) {
        this.handleError(e);
        this[this.$options.ACTION_FLAGS[action]] = false;
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
    :default-editor-mode="$options.DEFAULT_EDITOR_MODE"
    :disable-update="disableScanExecutionUpdate"
    :editor-modes="$options.EDITOR_MODES"
    :is-editing="isEditing"
    :is-removing-policy="isRemovingPolicy"
    :is-updating-policy="isCreatingMR"
    :policy-name="policy.name"
    :yaml-editor-value="yamlEditorValue"
    @remove-policy="handleModifyPolicy('REMOVE')"
    @save-policy="handleModifyPolicy()"
    @update-yaml="updateYaml"
  >
    <template #save-button-text>
      {{ $options.i18n.createMergeRequest }}
    </template>
  </policy-editor-layout>
</template>
