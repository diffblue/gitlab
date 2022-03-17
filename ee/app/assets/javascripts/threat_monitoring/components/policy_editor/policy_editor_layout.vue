<script>
import { GlButtonGroup, GlButton, GlModal, GlModalDirective, GlTooltipDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { DELETE_MODAL_CONFIG, EDITOR_MODES, EDITOR_MODE_RULE, EDITOR_MODE_YAML } from './constants';

export default {
  i18n: {
    DELETE_MODAL_CONFIG,
  },
  components: {
    GlButton,
    GlModal,
    GlButtonGroup,
    PolicyYamlEditor: () =>
      import(/* webpackChunkName: 'policy_yaml_editor' */ '../policy_yaml_editor.vue'),
  },
  directives: { GlModal: GlModalDirective, GlTooltip: GlTooltipDirective },
  inject: ['policiesPath'],
  props: {
    customSaveButtonText: {
      type: String,
      required: false,
      default: '',
    },
    customSaveTooltipText: {
      type: String,
      required: false,
      default: '',
    },
    defaultEditorMode: {
      type: String,
      required: false,
      default: EDITOR_MODE_RULE,
    },
    disableTooltip: {
      type: Boolean,
      required: false,
      default: true,
    },
    disableUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    editorModes: {
      type: Array,
      required: false,
      default: () => EDITOR_MODES,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    isRemovingPolicy: {
      type: Boolean,
      required: false,
      default: false,
    },
    isUpdatingPolicy: {
      type: Boolean,
      required: false,
      default: false,
    },
    policyName: {
      type: String,
      required: false,
      default: '',
    },
    yamlEditorValue: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      selectedEditorMode: this.defaultEditorMode,
    };
  },
  computed: {
    deleteModalTitle() {
      return sprintf(s__('NetworkPolicies|Delete policy: %{policy}'), { policy: this.policyName });
    },
    saveTooltipText() {
      return this.customSaveTooltipText || this.saveButtonText;
    },
    saveButtonText() {
      return (
        this.customSaveButtonText ||
        (this.isEditing
          ? s__('NetworkPolicies|Save changes')
          : s__('NetworkPolicies|Create policy'))
      );
    },
    shouldShowRuleEditor() {
      return this.selectedEditorMode === EDITOR_MODE_RULE;
    },
    shouldShowYamlEditor() {
      return this.selectedEditorMode === EDITOR_MODE_YAML;
    },
  },
  methods: {
    removePolicy() {
      this.$emit('remove-policy');
    },
    savePolicy() {
      this.$emit('save-policy', this.selectedEditorMode);
    },
    updateEditorMode(mode) {
      this.selectedEditorMode = mode;
      this.$emit('update-editor-mode', mode);
    },
    updateYaml(manifest) {
      this.$emit('update-yaml', manifest);
    },
  },
};
</script>

<template>
  <section class="gl-mt-6">
    <div class="gl-mb-5">
      <div class="gl-border-b-solid gl-border-b-1 gl-border-gray-100 gl-mb-6 gl-pb-6">
        <gl-button-group :vertical="false">
          <gl-button
            v-for="{ text, value } in editorModes"
            :key="value"
            :data-testid="`button-${value}`"
            :selected="selectedEditorMode === value"
            type="button"
            @click="updateEditorMode(value)"
          >
            {{ text }}
          </gl-button>
        </gl-button-group>
      </div>
      <div class="gl-display-flex gl-sm-flex-direction-column">
        <section class="gl-w-full gl-mr-7">
          <div v-if="shouldShowRuleEditor" data-testid="rule-editor">
            <slot name="rule-editor"></slot>
          </div>
          <policy-yaml-editor
            v-if="shouldShowYamlEditor"
            data-testid="policy-yaml-editor"
            :value="yamlEditorValue"
            :read-only="false"
            @input="updateYaml"
          />
        </section>
        <section
          v-if="shouldShowRuleEditor"
          class="gl-md-w-50p gl-md-max-w-30p gl-p-5 gl-bg-gray-10 gl-ml-11 gl-align-self-start"
          data-testid="rule-editor-preview"
        >
          <slot name="rule-editor-preview"></slot>
        </section>
      </div>
    </div>
    <slot name="bottom"></slot>
    <span
      v-gl-tooltip.hover.focus="{ disabled: disableTooltip }"
      class="gl-pt-2"
      :title="saveTooltipText"
      data-testid="save-policy-tooltip"
    >
      <gl-button
        type="submit"
        variant="confirm"
        data-testid="save-policy"
        :loading="isUpdatingPolicy"
        :disabled="disableUpdate"
        @click="savePolicy"
      >
        {{ saveButtonText }}
      </gl-button>
    </span>
    <gl-button
      v-if="isEditing"
      v-gl-modal="'delete-modal'"
      category="secondary"
      variant="danger"
      data-testid="delete-policy"
      :loading="isRemovingPolicy"
      >{{ s__('NetworkPolicies|Delete policy') }}</gl-button
    >
    <gl-button category="secondary" :href="policiesPath">{{ __('Cancel') }}</gl-button>
    <gl-modal
      modal-id="delete-modal"
      :title="deleteModalTitle"
      :action-secondary="$options.i18n.DELETE_MODAL_CONFIG.secondary"
      :action-cancel="$options.i18n.DELETE_MODAL_CONFIG.cancel"
      @secondary="removePolicy"
    >
      {{
        s__(
          'NetworkPolicies|Are you sure you want to delete this policy? This action cannot be undone.',
        )
      }}
    </gl-modal>
  </section>
</template>
