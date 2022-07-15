<script>
import { GlSprintf, GlForm, GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';
import { REPORT_TYPES_DEFAULT, SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import PolicyRuleMultiSelect from 'ee/security_orchestration/components/policy_rule_multi_select.vue';
import { ALL_BRANCHES } from 'ee/vue_shared/components/branches_selector/constants';
import { APPROVAL_VULNERABILITY_STATES } from './lib';

export default {
  scanResultRuleCopy: s__(
    'ScanResultPolicy|%{ifLabelStart}if%{ifLabelEnd} %{scanners} find(s) more than %{vulnerabilitiesAllowed} %{severities} %{vulnerabilityStates} vulnerabilities in an open merge request targeting %{branches}',
  ),
  components: {
    GlSprintf,
    GlForm,
    GlButton,
    GlFormInput,
    ProtectedBranchesSelector,
    GlFormGroup,
    PolicyRuleMultiSelect,
  },
  inject: ['namespaceId'],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      reportTypesKeys: Object.keys(REPORT_TYPES_DEFAULT),
    };
  },
  computed: {
    branchesToAdd: {
      get() {
        return this.initRule.branches;
      },
      set(value) {
        const branches = value.id === ALL_BRANCHES.id ? [] : [value.name];
        this.triggerChanged({ branches });
      },
    },
    severityLevelsToAdd: {
      get() {
        return this.initRule.severity_levels;
      },
      set(values) {
        this.triggerChanged({ severity_levels: values });
      },
    },
    scannersToAdd: {
      get() {
        return this.initRule.scanners.length === 0 ? this.reportTypesKeys : this.initRule.scanners;
      },
      set(values) {
        this.triggerChanged({
          scanners: values.length === this.reportTypesKeys.length ? [] : values,
        });
      },
    },
    vulnerabilityStates: {
      get() {
        return this.initRule.vulnerability_states;
      },
      set(values) {
        this.triggerChanged({ vulnerability_states: values });
      },
    },
    vulnerabilitiesAllowed: {
      get() {
        return this.initRule.vulnerabilities_allowed;
      },
      set(value) {
        this.triggerChanged({ vulnerabilities_allowed: parseInt(value, 10) });
      },
    },
  },
  methods: {
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
  },
  REPORT_TYPES_DEFAULT,
  SEVERITY_LEVELS,
  APPROVAL_VULNERABILITY_STATES,
  i18n: {
    severityLevels: s__('ScanResultPolicy|severity levels'),
    scanners: s__('ScanResultPolicy|scanners'),
    vulnerabilityStates: s__('ScanResultPolicy|vulnerability states'),
  },
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-rounded-base gl-pl-5 gl-pr-7 gl-pt-5 gl-relative gl-pb-4">
    <gl-form inline @submit.prevent>
      <gl-sprintf :message="$options.scanResultRuleCopy">
        <template #ifLabel="{ content }">
          <label for="scanners" class="text-uppercase gl-font-lg gl-mr-3">{{ content }}</label>
        </template>

        <template #scanners>
          <policy-rule-multi-select
            v-model="scannersToAdd"
            class="gl-mr-3"
            :item-type-name="$options.i18n.scanners"
            :items="$options.REPORT_TYPES_DEFAULT"
            data-testid="scanners-select"
          />
        </template>

        <template #branches>
          <gl-form-group class="gl-ml-3 gl-mr-3 gl-mb-3!" data-testid="branches-group">
            <protected-branches-selector
              v-model="branchesToAdd"
              :project-id="namespaceId"
              :selected-branches-names="branchesToAdd"
            />
          </gl-form-group>
        </template>

        <template #vulnerabilitiesAllowed>
          <gl-form-input
            v-model="vulnerabilitiesAllowed"
            type="number"
            class="gl-w-11! gl-mr-3 gl-ml-3"
            :min="0"
            data-testid="vulnerabilities-allowed-input"
          />
        </template>

        <template #severities>
          <policy-rule-multi-select
            v-model="severityLevelsToAdd"
            class="gl-mr-3 gl-ml-3"
            :item-type-name="$options.i18n.severityLevels"
            :items="$options.SEVERITY_LEVELS"
            data-testid="severities-select"
          />
        </template>

        <template #vulnerabilityStates>
          <policy-rule-multi-select
            v-model="vulnerabilityStates"
            class="gl-ml-3"
            :item-type-name="$options.i18n.vulnerabilityStates"
            :items="$options.APPROVAL_VULNERABILITY_STATES"
            data-testid="vulnerability-states-select"
          />
        </template>
      </gl-sprintf>
    </gl-form>
    <gl-button
      icon="remove"
      category="tertiary"
      class="gl-absolute gl-top-1 gl-right-1"
      :aria-label="__('Remove')"
      data-testid="remove-rule"
      @click="$emit('remove', $event)"
    />
  </div>
</template>
