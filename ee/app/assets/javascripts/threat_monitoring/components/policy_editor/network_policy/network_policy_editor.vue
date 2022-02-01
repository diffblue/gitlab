<script>
import {
  GlEmptyState,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlFormCheckbox,
  GlButton,
  GlAlert,
  GlIcon,
  GlCollapse,
  GlCollapseToggleDirective,
} from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { removeUnnecessaryDashes } from 'ee/threat_monitoring/utils';
import { redirectTo } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import { EDITOR_MODES, EDITOR_MODE_YAML, PARSING_ERROR_MESSAGE } from '../constants';
import DimDisableContainer from '../dim_disable_container.vue';
import PolicyActionPicker from '../policy_action_picker.vue';
import PolicyAlertPicker from '../policy_alert_picker.vue';
import PolicyEditorLayout from '../policy_editor_layout.vue';
import PolicyPreviewHuman from '../policy_preview_human.vue';
import {
  DEFAULT_NETWORK_POLICY,
  RuleTypeEndpoint,
  ProjectIdLabel,
  fromYaml,
  humanizeNetworkPolicy,
  buildRule,
  toYaml,
} from './lib';
import PolicyRuleBuilder from './policy_rule_builder.vue';

export default {
  EDITOR_MODES,
  i18n: {
    basicInformation: __('Basic information'),
    actions: s__('SecurityOrchestration|Actions'),
    addRule: s__('SecurityOrchestration|Add rule'),
    description: __('Description'),
    toggleLabel: s__('SecurityOrchestration|Policy status'),
    PARSING_ERROR_MESSAGE,
    name: __('Name'),
    noEnvironmentDescription: s__(
      'NetworkPolicies|Network Policies can be used to limit which network traffic is allowed between containers inside the cluster.',
    ),
    noEnvironmentButton: __('Learn more'),
    yamlPreview: s__('SecurityOrchestration|.yaml preview'),
    policySummary: s__('SecurityOrchestration|Policy summary'),
    policyEnabled: __('Enabled'),
    rules: s__('SecurityOrchestration|Rules'),
    saveButtonTooltip: s__(
      'NetworkPolicies|Network policy can be created after the environment is loaded successfully.',
    ),
  },
  policyPreviewHumanCollapseId: 'policy-preview-human-collapse',
  components: {
    GlEmptyState,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlFormCheckbox,
    GlButton,
    GlAlert,
    GlIcon,
    GlCollapse,
    PolicyRuleBuilder,
    PolicyActionPicker,
    PolicyAlertPicker,
    PolicyEditorLayout,
    PolicyPreviewHuman,
    DimDisableContainer,
  },
  directives: {
    CollapseToggle: GlCollapseToggleDirective,
  },
  inject: [
    'networkDocumentationPath',
    'policyEditorEmptyStateSvgPath',
    'projectId',
    'policiesPath',
  ],
  props: {
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
    const policy = this.existingPolicy
      ? fromYaml(this.existingPolicy.manifest)
      : { ...DEFAULT_NETWORK_POLICY, rules: [buildRule()] };
    policy.labels = { [ProjectIdLabel]: this.projectId };

    const yamlEditorValue = this.existingPolicy
      ? removeUnnecessaryDashes(this.existingPolicy.manifest)
      : '';

    return {
      isPolicyPreviewHumanVisible: true,
      yamlEditorValue,
      yamlEditorError: policy.error ? true : null,
      policy,
    };
  },
  computed: {
    customSaveTooltipText() {
      return !this.retrievedEnvironments ? this.$options.i18n.saveButtonTooltip : '';
    },
    humanizedPolicy() {
      return this.policy.error ? null : humanizeNetworkPolicy(this.policy);
    },
    policyAlert() {
      return Boolean(this.policy.annotations);
    },
    policyYaml() {
      return this.hasParsingError ? '' : toYaml(this.policy);
    },
    retrievedEnvironments() {
      return !this.isLoadingEnvironments && Boolean(this.environments.length);
    },
    ...mapState('threatMonitoring', [
      'currentEnvironmentId',
      'environments',
      'isLoadingEnvironments',
      'hasEnvironment',
    ]),
    ...mapState('networkPolicies', [
      'isUpdatingPolicy',
      'isRemovingPolicy',
      'errorUpdatingPolicy',
      'errorRemovingPolicy',
    ]),
    hasParsingError() {
      return Boolean(this.yamlEditorError);
    },
  },
  methods: {
    ...mapActions('networkPolicies', ['createPolicy', 'updatePolicy', 'deletePolicy']),
    addRule() {
      this.policy.rules.push(buildRule(RuleTypeEndpoint));
    },
    handleAlertUpdate(includeAlert) {
      this.policy.annotations = includeAlert ? { 'app.gitlab.com/alert': 'true' } : '';
    },
    isNotFirstRule(index) {
      return index > 0;
    },
    updateEndpointMatchMode(mode) {
      this.policy.endpointMatchMode = mode;
    },
    updateEndpointLabels(labels) {
      this.policy.endpointLabels = labels;
    },
    updateRuleType(ruleIndex, ruleType) {
      const rule = this.policy.rules[ruleIndex];
      this.policy.rules.splice(ruleIndex, 1, buildRule(ruleType, rule));
    },
    removeRule(ruleIndex) {
      this.policy.rules.splice(ruleIndex, 1);
    },
    updateYaml(manifest) {
      this.yamlEditorValue = manifest;
      this.yamlEditorError = null;

      try {
        const newPolicy = fromYaml(manifest);
        if (newPolicy.error) {
          throw new Error(newPolicy.error);
        }
        Object.assign(this.policy, newPolicy);
      } catch (error) {
        this.yamlEditorError = error;
      }
    },
    changeEditorMode(mode) {
      if (mode === EDITOR_MODE_YAML && !this.hasParsingError) {
        this.yamlEditorValue = toYaml(this.policy);
      }
    },
    savePolicy(mode) {
      const saveFn = this.isEditing ? this.updatePolicy : this.createPolicy;
      const policy = {
        manifest: mode === EDITOR_MODE_YAML ? this.yamlEditorValue : toYaml(this.policy),
      };
      if (this.isEditing) {
        policy.name = this.existingPolicy.name;
      }

      return saveFn({ environmentId: this.currentEnvironmentId, policy }).then(() => {
        if (!this.errorUpdatingPolicy) redirectTo(this.policiesPath);
      });
    },
    removePolicy() {
      const policy = { name: this.existingPolicy.name, manifest: this.yamlEditorValue };

      return this.deletePolicy({ environmentId: this.currentEnvironmentId, policy }).then(() => {
        if (!this.errorRemovingPolicy) redirectTo(this.policiesPath);
      });
    },
  },
};
</script>

<template>
  <policy-editor-layout
    v-if="hasEnvironment"
    :custom-save-tooltip-text="customSaveTooltipText"
    :disable-tooltip="retrievedEnvironments"
    :disable-update="!retrievedEnvironments"
    :is-editing="isEditing"
    :is-removing-policy="isRemovingPolicy"
    :is-updating-policy="isUpdatingPolicy"
    :policy-name="policy.name"
    :yaml-editor-value="yamlEditorValue"
    @remove-policy="removePolicy"
    @save-policy="savePolicy"
    @update-editor-mode="changeEditorMode"
    @update-yaml="updateYaml"
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

      <h5 class="gl-mt-0 gl-mb-5">
        {{ $options.i18n.basicInformation }}
      </h5>

      <gl-form-group :label="$options.i18n.name" label-for="policyName">
        <gl-form-input id="policyName" v-model="policy.name" :disabled="hasParsingError" />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.description" label-for="policyDescription" optional>
        <gl-form-textarea
          id="policyDescription"
          v-model="policy.description"
          :disabled="hasParsingError"
        />
      </gl-form-group>

      <gl-form-group
        :label="$options.i18n.toggleLabel"
        :disabled="hasParsingError"
        data-testid="policy-enable"
        class="gl-mb-6"
      >
        <gl-form-checkbox id="policyStatus" v-model="policy.isEnabled">
          {{ $options.i18n.policyEnabled }}
        </gl-form-checkbox>
      </gl-form-group>

      <dim-disable-container
        class="gl-mb-6"
        data-testid="rule-builder-container"
        :disabled="hasParsingError"
      >
        <template #title>
          <h5 class="gl-mt-0 gl-mb-5">
            {{ $options.i18n.rules }}
          </h5>
        </template>

        <template #disabled>
          <div
            class="gl-bg-gray-10 gl-border-solid gl-border-1 gl-border-gray-100 gl-rounded-base gl-p-6"
          ></div>
        </template>

        <policy-rule-builder
          v-for="(rule, index) in policy.rules"
          :key="index"
          class="gl-mb-4"
          :rule="rule"
          :endpoint-match-mode="policy.endpointMatchMode"
          :endpoint-labels="policy.endpointLabels"
          :endpoint-selector-disabled="isNotFirstRule(index)"
          @rule-type-change="updateRuleType(index, $event)"
          @endpoint-match-mode-change="updateEndpointMatchMode"
          @endpoint-labels-change="updateEndpointLabels"
          @remove="removeRule(index)"
        />

        <gl-button variant="link" data-testid="add-rule" icon="plus" @click="addRule">
          {{ $options.i18n.addRule }}
        </gl-button>
      </dim-disable-container>

      <dim-disable-container
        class="gl-mb-6"
        data-testid="policy-action-container"
        :disabled="hasParsingError"
      >
        <template #title>
          <h5 class="gl-mt-0 gl-mb-5">{{ $options.i18n.actions }}</h5>
        </template>

        <template #disabled>
          <div class="gl-bg-gray-10 gl-p-6"></div>
        </template>

        <policy-action-picker />
        <policy-alert-picker :policy-alert="policyAlert" @update-alert="handleAlertUpdate" />
      </dim-disable-container>

      <div v-if="!hasParsingError" class="gl-my-6">
        <gl-button
          v-collapse-toggle="$options.policyPreviewHumanCollapseId"
          category="tertiary"
          class="gl-font-weight-bold gl-bg-transparent! gl-px-0!"
        >
          {{ $options.i18n.policySummary }}
          <gl-icon :name="isPolicyPreviewHumanVisible ? 'angle-up' : 'angle-down'" :size="12" />
        </gl-button>
        <gl-collapse
          :id="$options.policyPreviewHumanCollapseId"
          v-model="isPolicyPreviewHumanVisible"
        >
          <policy-preview-human
            class="gl-bg-gray-10 gl-py-3 gl-px-4"
            :policy-description="humanizedPolicy"
          />
        </gl-collapse>
      </div>
    </template>
    <template #rule-editor-preview>
      <h5>{{ $options.i18n.yamlPreview }}</h5>
      <pre
        data-testid="yaml-preview"
        class="gl-border-none gl-p-0"
        :class="{ 'gl-opacity-5': hasParsingError }"
        >{{ policyYaml || yamlEditorValue }}</pre
      >
    </template>
  </policy-editor-layout>
  <gl-empty-state
    v-else
    :description="$options.i18n.noEnvironmentDescription"
    :primary-button-link="networkDocumentationPath"
    :primary-button-text="$options.i18n.noEnvironmentButton"
    :svg-path="policyEditorEmptyStateSvgPath"
    title=""
  />
</template>
