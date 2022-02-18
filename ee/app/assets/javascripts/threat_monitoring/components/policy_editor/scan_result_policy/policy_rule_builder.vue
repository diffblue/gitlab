<script>
import { GlSprintf, GlForm, GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  REPORT_TYPES_NO_CLUSTER_IMAGE,
  SEVERITY_LEVELS,
} from 'ee/security_dashboard/store/constants';
import ProtectedBranchesSelector from 'ee/vue_shared/components/branches_selector/protected_branches_selector.vue';
import PolicyRuleMultiSelect from 'ee/threat_monitoring/components/policy_rule_multi_select.vue';
import { APPROVAL_VULNERABILITY_STATES } from 'ee/approvals/constants';

export default {
  scanResultRuleCopy: s__(
    'ScanResultPolicy|%{ifLabelStart}if%{ifLabelEnd} %{scanners} scan in an open merge request targeting the %{branches} branch(es) finds %{vulnerabilitiesAllowed} or more %{severities} vulnerabilities that are %{vulnerabilityStates}',
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
  inject: ['projectId'],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      reportTypesKeys: Object.keys(REPORT_TYPES_NO_CLUSTER_IMAGE),
    };
  },
  computed: {
    branchesToAdd: {
      get() {
        return this.initRule.branches;
      },
      set(value) {
        const branches = value.id === null ? [] : [value.name];
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
        return this.initRule.scanners;
      },
      set(values) {
        this.triggerChanged({ scanners: values });
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
  REPORT_TYPES_NO_CLUSTER_IMAGE,
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
  <div
    class="gl-bg-gray-10 gl-border-solid gl-border-1 gl-border-gray-100 gl-rounded-base px-3 pt-3 gl-relative gl-pb-4"
  >
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
            :items="$options.REPORT_TYPES_NO_CLUSTER_IMAGE"
            data-testid="scanners-select"
          />
        </template>

        <template #branches>
          <gl-form-group class="gl-ml-3 gl-mr-3 gl-mb-3!" data-testid="branches-group">
            <protected-branches-selector
              v-model="branchesToAdd"
              :project-id="projectId"
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
      class="gl-absolute gl-top-3 gl-right-3"
      :aria-label="__('Remove')"
      data-testid="remove-rule"
      @click="$emit('remove', $event)"
    />
  </div>
</template>
