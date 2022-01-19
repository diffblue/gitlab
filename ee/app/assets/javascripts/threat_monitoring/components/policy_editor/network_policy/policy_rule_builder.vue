<script>
import { GlSprintf, GlForm, GlFormSelect, GlFormInput, GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  RuleTypeNetwork,
  RuleDirectionInbound,
  RuleDirectionOutbound,
  EndpointMatchModeAny,
  EndpointMatchModeLabel,
  RuleTypeEndpoint,
  RuleTypeEntity,
  RuleTypeCIDR,
  RuleTypeFQDN,
  PortMatchModeAny,
  PortMatchModePortProtocol,
} from './lib';
import PolicyRuleCIDR from './policy_rule_cidr.vue';
import PolicyRuleEndpoint from './policy_rule_endpoint.vue';
import PolicyRuleEntity from './policy_rule_entity.vue';
import PolicyRuleFQDN from './policy_rule_fqdn.vue';

export default {
  components: {
    GlSprintf,
    GlForm,
    GlFormSelect,
    GlFormInput,
    GlButton,
    PolicyRuleEndpoint,
    PolicyRuleEntity,
    'policy-rule-cidr': PolicyRuleCIDR,
    'policy-rule-fqdn': PolicyRuleFQDN,
  },
  props: {
    rule: {
      type: Object,
      required: true,
    },
    endpointMatchMode: {
      type: String,
      required: true,
    },
    endpointLabels: {
      type: String,
      required: true,
    },
    endpointSelectorDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return { ruleType: RuleTypeNetwork };
  },
  computed: {
    shouldShowEndpointLabels() {
      return this.endpointMatchMode === EndpointMatchModeLabel;
    },
    sprintfTemplate() {
      if (this.rule.direction === RuleDirectionInbound) {
        return s__(
          'NetworkPolicies|%{ifLabelStart}if%{ifLabelEnd} %{ruleType} %{isLabelStart}is%{isLabelEnd} %{ruleDirection} %{ruleSelector} %{directionLabelStart}and is inbound from a%{directionLabelEnd} %{rule} %{portsLabelStart}on%{portsLabelEnd} %{ports}',
        );
      }

      return s__(
        'NetworkPolicies|%{ifLabelStart}if%{ifLabelEnd} %{ruleType} %{isLabelStart}is%{isLabelEnd} %{ruleDirection} %{ruleSelector} %{directionLabelStart}and is outbound to a%{directionLabelEnd} %{rule} %{portsLabelStart}on%{portsLabelEnd} %{ports}',
      );
    },
    currentRuleComponent() {
      const { ruleComponents } = this.$options;
      return ruleComponents[this.rule.ruleType] || ruleComponents[RuleTypeEndpoint];
    },
    ruleComponentName() {
      const { component } = this.currentRuleComponent;
      return component;
    },
    ruleComponentModel: {
      get() {
        const { field } = this.currentRuleComponent;
        return this.rule[field];
      },
      set(value) {
        const { field } = this.currentRuleComponent;
        // eslint-disable-next-line vue/no-mutating-props
        this.rule[field] = value;
      },
    },
    shouldShowPorts() {
      return this.rule.portMatchMode === PortMatchModePortProtocol;
    },
  },
  ruleTypes: [{ value: RuleTypeNetwork, text: s__('NetworkPolicies|Network traffic') }],
  trafficDirections: [
    { value: RuleDirectionInbound, text: s__('NetworkPolicies|inbound to') },
    { value: RuleDirectionOutbound, text: s__('NetworkPolicies|outbound from') },
  ],
  endpointMatchModes: [
    { value: EndpointMatchModeAny, text: s__('NetworkPolicies|any pod') },
    { value: EndpointMatchModeLabel, text: s__('NetworkPolicies|pods with labels') },
  ],
  ruleModes: [
    { value: RuleTypeEndpoint, text: s__('NetworkPolicies|pod with labels') },
    { value: RuleTypeEntity, text: s__('NetworkPolicies|entity') },
    { value: RuleTypeCIDR, text: s__('NetworkPolicies|IP/subnet') },
    { value: RuleTypeFQDN, text: s__('NetworkPolicies|domain name') },
  ],
  portMatchModes: [
    { value: PortMatchModeAny, text: s__('NetworkPolicies|any port') },
    { value: PortMatchModePortProtocol, text: s__('NetworkPolicies|ports/protocols') },
  ],
  ruleComponents: {
    [RuleTypeEndpoint]: {
      component: 'policy-rule-endpoint',
      field: 'matchLabels',
    },
    [RuleTypeEntity]: {
      component: 'policy-rule-entity',
      field: 'entities',
    },
    [RuleTypeCIDR]: {
      component: 'policy-rule-cidr',
      field: 'cidr',
    },
    [RuleTypeFQDN]: {
      component: 'policy-rule-fqdn',
      field: 'fqdn',
    },
  },
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-px-3 gl-pt-3 gl-relative gl-display-flex">
    <gl-form class="gl-flex-grow-1" inline @submit.prevent>
      <gl-sprintf :message="sprintfTemplate">
        <template #ifLabel="{ content }">
          <label for="ruleType" class="text-uppercase gl-font-lg gl-mr-4 gl-mb-3!">{{
            content
          }}</label>
        </template>

        <template #ruleType>
          <gl-form-select
            id="ruleType"
            class="gl-mr-4 gl-mb-3"
            :value="ruleType"
            :options="$options.ruleTypes"
          />
        </template>

        <template #isLabel="{ content }">
          <label for="direction" class="gl-mr-4 gl-mb-3! gl-font-weight-normal">{{
            content
          }}</label>
        </template>

        <template #ruleDirection>
          <!-- eslint-disable vue/no-mutating-props -->
          <gl-form-select
            id="direction"
            v-model="rule.direction"
            class="gl-mr-4 gl-mb-3"
            :options="$options.trafficDirections"
          />
          <!-- eslint-enable vue/no-mutating-props -->
        </template>

        <template #ruleSelector>
          <gl-form-select
            data-testid="endpoint-match-mode"
            class="gl-mr-4 gl-mb-3"
            :value="endpointMatchMode"
            :disabled="endpointSelectorDisabled"
            :options="$options.endpointMatchModes"
            @change="$emit('endpoint-match-mode-change', $event)"
          />
          <!-- placeholder is the same in all languages-->
          <!-- eslint-disable @gitlab/vue-require-i18n-attribute-strings -->
          <gl-form-input
            v-if="shouldShowEndpointLabels"
            data-testid="endpoint-labels"
            class="gl-mr-4 gl-mb-3 gl-bg-white!"
            placeholder="key:value"
            :value="endpointLabels"
            :disabled="endpointSelectorDisabled"
            @update="$emit('endpoint-labels-change', $event)"
          />
          <!-- eslint-enable @gitlab/vue-require-i18n-attribute-strings -->
        </template>

        <template #directionLabel="{ content }">
          <label for="ruleMode" class="gl-mr-4 gl-mb-3! gl-font-weight-normal">{{ content }}</label>
        </template>

        <template #rule>
          <gl-form-select
            id="ruleMode"
            class="gl-mr-4 gl-mb-3"
            :value="rule.ruleType"
            :options="$options.ruleModes"
            @change="$emit('rule-type-change', $event)"
          />

          <component :is="ruleComponentName" v-model="ruleComponentModel" class="gl-mr-4 gl-mb-3" />
        </template>

        <template #portsLabel="{ content }">
          <label for="portMatch" class="gl-mr-4 gl-mb-3! gl-font-weight-normal">{{
            content
          }}</label>
        </template>

        <template #ports>
          <!-- eslint-disable vue/no-mutating-props -->
          <gl-form-select
            id="portMatch"
            v-model="rule.portMatchMode"
            class="gl-mr-4 gl-mb-3"
            :options="$options.portMatchModes"
          />
          <!-- placeholder is the same in all languages-->
          <!-- eslint-disable @gitlab/vue-require-i18n-attribute-strings -->
          <gl-form-input
            v-if="shouldShowPorts"
            v-model="rule.ports"
            data-testid="ports"
            class="gl-mr-4 gl-mb-3 gl-bg-white!"
            placeholder="80/tcp"
          />
          <!-- eslint-enable @gitlab/vue-require-i18n-attribute-strings -->
          <!-- eslint-enable vue/no-mutating-props -->
        </template>
      </gl-sprintf>
    </gl-form>
    <gl-button
      icon="remove"
      category="tertiary"
      class="gl-align-self-start gl-ml-3"
      :aria-label="__('Remove')"
      data-testid="remove-rule"
      @click="$emit('remove')"
    />
  </div>
</template>
