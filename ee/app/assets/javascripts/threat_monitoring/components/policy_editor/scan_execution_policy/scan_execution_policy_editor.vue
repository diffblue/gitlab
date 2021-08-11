<script>
import { removeUnnecessaryDashes } from 'ee/threat_monitoring/utils';
import { joinPaths, visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { EDITOR_MODES, EDITOR_MODE_YAML } from '../constants';
import PolicyEditorLayout from '../policy_editor_layout.vue';
import { DEFAULT_SCAN_EXECUTION_POLICY, fromYaml, GRAPHQL_ERROR_MESSAGE, savePolicy } from './lib';

export default {
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
    async handleSavePolicy() {
      this.$emit('error', '');
      this.isCreatingMR = true;

      try {
        const { currentAssignedPolicyProject, mergeRequest } = await savePolicy({
          assignedPolicyProject: this.assignedPolicyProject,
          projectPath: this.projectPath,
          yamlEditorValue: this.yamlEditorValue,
        });

        visitUrl(
          joinPaths(
            gon.relative_url_root || '/',
            currentAssignedPolicyProject.fullPath,
            '/-/merge_requests',
            mergeRequest.id,
          ),
        );
      } catch (e) {
        if (e.message.toLowerCase().includes('graphql')) {
          this.$emit('error', GRAPHQL_ERROR_MESSAGE);
        } else {
          this.$emit('error', e.message);
        }
        this.isCreatingMR = false;
      }
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
    :is-updating-policy="isCreatingMR"
    :policy-name="policy.name"
    :yaml-editor-value="yamlEditorValue"
    @save-policy="handleSavePolicy"
    @update-yaml="updateYaml"
  >
    <template #save-button-text>
      {{ $options.i18n.createMergeRequest }}
    </template>
  </policy-editor-layout>
</template>
