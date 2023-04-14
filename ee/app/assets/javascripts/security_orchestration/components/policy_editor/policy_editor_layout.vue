<script>
import {
  GlAlert,
  GlButton,
  GlFormGroup,
  GlFormInput,
  GlFormRadioGroup,
  GlFormTextarea,
  GlIcon,
  GlModal,
  GlModalDirective,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import SegmentedControlButtonGroup from '~/vue_shared/components/segmented_control_button_group.vue';
import { NAMESPACE_TYPES } from '../../constants';
import { POLICY_TYPE_COMPONENT_OPTIONS } from '../constants';
import {
  DELETE_MODAL_CONFIG,
  EDITOR_MODES,
  EDITOR_MODE_RULE,
  EDITOR_MODE_YAML,
  POLICY_RUN_TIME_MESSAGE,
  POLICY_RUN_TIME_TOOLTIP,
} from './constants';

export default {
  i18n: {
    DELETE_MODAL_CONFIG,
    POLICY_RUN_TIME_MESSAGE,
    POLICY_RUN_TIME_TOOLTIP,
    description: __('Description'),
    failedValidationText: __('This field is required'),
    name: __('Name'),
    toggleLabel: s__('SecurityOrchestration|Policy status'),
    yamlPreview: s__('SecurityOrchestration|.yaml preview'),
  },
  STATUS_OPTIONS: [
    { value: true, text: __('Enabled') },
    { value: false, text: __('Disabled') },
  ],
  components: {
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlFormRadioGroup,
    GlIcon,
    GlModal,
    SegmentedControlButtonGroup,
    PolicyYamlEditor: () =>
      import(/* webpackChunkName: 'policy_yaml_editor' */ '../policy_yaml_editor.vue'),
  },
  directives: { GlModal: GlModalDirective, GlTooltip: GlTooltipDirective },
  inject: ['namespaceType', 'policiesPath'],
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
    hasParsingError: {
      type: Boolean,
      required: false,
      default: false,
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
    parsingError: {
      type: String,
      required: false,
      default: '',
    },
    policy: {
      type: Object,
      required: true,
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
      showValidation: false,
    };
  },
  computed: {
    deleteModalTitle() {
      return sprintf(s__('SecurityOrchestration|Delete policy: %{policy}'), {
        policy: this.policy.name,
      });
    },
    hasValidName() {
      return this.policy.name !== '';
    },
    saveTooltipText() {
      return this.customSaveTooltipText || this.saveButtonText;
    },
    saveButtonText() {
      return (
        this.customSaveButtonText ||
        (this.isEditing
          ? s__('SecurityOrchestration|Save changes')
          : s__('SecurityOrchestration|Create policy'))
      );
    },
    shouldShowRuleEditor() {
      return this.selectedEditorMode === EDITOR_MODE_RULE;
    },
    shouldShowYamlEditor() {
      return this.selectedEditorMode === EDITOR_MODE_YAML;
    },
    shouldShowRuntimeMessage() {
      return (
        this.policy.type === POLICY_TYPE_COMPONENT_OPTIONS.scanResult.urlParameter &&
        this.namespaceType !== NAMESPACE_TYPES.PROJECT
      );
    },
  },
  watch: {
    selectedEditorMode(val) {
      this.$emit('update-editor-mode', val);
    },
  },
  methods: {
    removePolicy() {
      this.$emit('remove-policy');
    },
    savePolicy() {
      this.$emit('save-policy', this.selectedEditorMode);
    },
    setPolicyProperty(property, value) {
      if (property === 'name') {
        this.showValidation = true;
      }

      this.$emit('set-policy-property', property, value);
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
        <segmented-control-button-group v-model="selectedEditorMode" :options="editorModes" />
      </div>
      <div class="gl-display-flex gl-flex-direction-column gl-lg-flex-direction-row">
        <section class="gl-w-full gl-mr-7">
          <div v-if="shouldShowRuleEditor" data-testid="rule-editor">
            <gl-alert
              v-if="hasParsingError"
              data-testid="parsing-alert"
              class="gl-mb-5"
              variant="warning"
              :dismissible="false"
            >
              {{ parsingError }}
            </gl-alert>

            <gl-form-group
              :label="$options.i18n.name"
              label-for="policyName"
              :invalid-feedback="$options.i18n.failedValidationText"
            >
              <gl-form-input
                id="policyName"
                :disabled="hasParsingError"
                :state="hasValidName || !showValidation"
                :value="policy.name"
                required
                @input="setPolicyProperty('name', $event)"
              />
            </gl-form-group>

            <gl-form-group
              :label="$options.i18n.description"
              label-for="policyDescription"
              optional
            >
              <gl-form-textarea
                id="policyDescription"
                :disabled="hasParsingError"
                :value="policy.description"
                @input="setPolicyProperty('description', $event)"
              />
            </gl-form-group>

            <gl-form-group
              :label="$options.i18n.toggleLabel"
              :disabled="hasParsingError"
              data-testid="policy-enable"
            >
              <gl-form-radio-group
                :options="$options.STATUS_OPTIONS"
                :disabled="hasParsingError"
                :checked="policy.enabled"
                @change="setPolicyProperty('enabled', $event)"
              />
            </gl-form-group>

            <slot name="actions-first"></slot>
            <slot name="rules"></slot>
            <slot name="actions"></slot>
          </div>
          <policy-yaml-editor
            v-if="shouldShowYamlEditor"
            data-testid="policy-yaml-editor"
            :policy-type="policy.type"
            :value="yamlEditorValue"
            :read-only="false"
            @input="updateYaml"
          />
        </section>
        <section
          v-if="shouldShowRuleEditor"
          class="security-policies-bg-gray-10 gl-px-5 gl-pb-5 gl-w-full gl-lg-w-30p gl-lg-ml-10 gl-align-self-start"
          data-testid="rule-editor-preview"
        >
          <h5>{{ $options.i18n.yamlPreview }}</h5>
          <pre
            data-testid="yaml-preview"
            class="security-policies-bg-gray-10 security-policies-pre-min-width gl-white-space-pre-wrap gl-border-none gl-p-0"
            :class="{ 'gl-opacity-5': hasParsingError }"
            >{{ yamlEditorValue }}</pre
          >
        </section>
      </div>
    </div>
    <slot name="bottom"></slot>
    <div
      class="gl-display-flex gl-flex-direction-column gl-align-items-baseline"
      :class="{
        'gl-md-display-block': !shouldShowRuntimeMessage,
        'gl-lg-display-block': shouldShowRuntimeMessage,
      }"
    >
      <span
        v-gl-tooltip.hover.focus="{ disabled: disableTooltip }"
        class="gl-pt-2 gl-mr-3"
        :title="saveTooltipText"
        data-testid="save-policy-tooltip"
      >
        <gl-button
          type="submit"
          variant="confirm"
          data-testid="save-policy"
          :loading="isUpdatingPolicy"
          :disabled="disableUpdate || !hasValidName"
          @click="savePolicy"
        >
          {{ saveButtonText }}
        </gl-button>
      </span>
      <gl-button
        v-if="isEditing"
        v-gl-modal="'delete-modal'"
        class="gl-mt-5 gl-mr-3"
        :class="{
          'gl-md-mt-0': !shouldShowRuntimeMessage,
          'gl-lg-mt-0': shouldShowRuntimeMessage,
        }"
        category="secondary"
        variant="danger"
        data-testid="delete-policy"
        :loading="isRemovingPolicy"
      >
        {{ s__('SecurityOrchestration|Delete policy') }}
      </gl-button>
      <gl-button
        class="gl-mt-5"
        :class="{
          'gl-md-mt-0': !shouldShowRuntimeMessage,
          'gl-lg-mt-0': shouldShowRuntimeMessage,
        }"
        category="secondary"
        :href="policiesPath"
      >
        {{ __('Cancel') }}
      </gl-button>
      <span
        v-if="shouldShowRuntimeMessage"
        class="gl-mt-5 gl-lg-ml-10"
        :class="{
          'gl-md-mt-0': !shouldShowRuntimeMessage,
          'gl-lg-mt-0': shouldShowRuntimeMessage,
        }"
        data-testid="scan-result-policy-run-time-info"
      >
        <gl-icon v-gl-tooltip="$options.i18n.POLICY_RUN_TIME_TOOLTIP" name="information-o" />
        {{ $options.i18n.POLICY_RUN_TIME_MESSAGE }}
      </span>
    </div>
    <gl-modal
      modal-id="delete-modal"
      :title="deleteModalTitle"
      :action-secondary="$options.i18n.DELETE_MODAL_CONFIG.secondary"
      :action-cancel="$options.i18n.DELETE_MODAL_CONFIG.cancel"
      @secondary="removePolicy"
    >
      {{
        s__(
          'SecurityOrchestration|Are you sure you want to delete this policy? This action cannot be undone.',
        )
      }}
    </gl-modal>
  </section>
</template>
