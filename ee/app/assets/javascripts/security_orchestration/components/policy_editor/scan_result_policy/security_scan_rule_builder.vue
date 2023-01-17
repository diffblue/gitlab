<script>
import { GlSprintf, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';
import { REPORT_TYPES_DEFAULT, SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import PolicyRuleMultiSelect from '../../policy_rule_multi_select.vue';
import PolicyRuleBranchSelection from './policy_rule_branch_selection.vue';
import { APPROVAL_VULNERABILITY_STATES } from './lib';

export default {
  scanResultRuleCopy: s__(
    'ScanResultPolicy|from %{scanners} find(s) more than %{vulnerabilitiesAllowed} %{severities} %{vulnerabilityStates} vulnerabilities in an open merge request targeting %{branches}',
  ),
  components: {
    GlSprintf,
    GlFormInput,
    PolicyRuleBranchSelection,
    PolicyRuleMultiSelect,
  },
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  computed: {
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
        return this.initRule.scanners.length === 0
          ? this.$options.REPORT_TYPES_DEFAULT_KEYS
          : this.initRule.scanners;
      },
      set(values) {
        this.triggerChanged({
          scanners: values.length === this.$options.REPORT_TYPES_DEFAULT_KEYS.length ? [] : values,
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
  REPORT_TYPES_DEFAULT_KEYS: Object.keys(REPORT_TYPES_DEFAULT),
  REPORT_TYPES_DEFAULT,
  SEVERITY_LEVELS,
  APPROVAL_VULNERABILITY_STATES,
  i18n: {
    severityLevels: s__('ScanResultPolicy|severity levels'),
    scanners: s__('ScanResultPolicy|scanners'),
    vulnerabilityStates: s__('ScanResultPolicy|vulnerability states'),
    vulnerabilitiesAllowed: s__('ScanResultPolicy|vulnerabilities allowed'),
  },
};
</script>

<template>
  <div class="gl-display-inline! gl-line-height-42 gl-ml-3">
    <gl-sprintf :message="$options.scanResultRuleCopy">
      <template #scanners>
        <policy-rule-multi-select
          v-model="scannersToAdd"
          class="gl-mx-3 gl-display-inline! gl-vertical-align-middle"
          :item-type-name="$options.i18n.scanners"
          :items="$options.REPORT_TYPES_DEFAULT"
          data-testid="scanners-select"
        />
      </template>

      <template #branches>
        <policy-rule-branch-selection :init-rule="initRule" @changed="triggerChanged($event)" />
      </template>

      <template #vulnerabilitiesAllowed>
        <label for="vulnerabilities-allowed" class="gl-sr-only">{{
          $options.i18n.vulnerabilitiesAllowed
        }}</label>
        <gl-form-input
          id="vulnerabilities-allowed"
          v-model="vulnerabilitiesAllowed"
          type="number"
          class="gl-w-11! gl-mx-3 gl-display-inline! gl-vertical-align-middle"
          :min="0"
          data-testid="vulnerabilities-allowed-input"
        />
      </template>

      <template #severities>
        <policy-rule-multi-select
          v-model="severityLevelsToAdd"
          class="gl-ml-3 gl-display-inline! gl-vertical-align-middle"
          :item-type-name="$options.i18n.severityLevels"
          :items="$options.SEVERITY_LEVELS"
          data-testid="severities-select"
        />
      </template>

      <template #vulnerabilityStates>
        <policy-rule-multi-select
          v-model="vulnerabilityStates"
          class="gl-mx-3 gl-display-inline! gl-vertical-align-middle"
          :item-type-name="$options.i18n.vulnerabilityStates"
          :items="$options.APPROVAL_VULNERABILITY_STATES"
          data-testid="vulnerability-states-select"
        />
      </template>
    </gl-sprintf>
  </div>
</template>
