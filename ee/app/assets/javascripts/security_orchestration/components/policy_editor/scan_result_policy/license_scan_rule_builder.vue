<script>
import { GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import PolicyRuleBranchSelection from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_branch_selection.vue';
import PolicyRuleMultiSelect from 'ee/security_orchestration/components/policy_rule_multi_select.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default {
  components: {
    GlSprintf,
    GlCollapsibleListbox,
    PolicyRuleBranchSelection,
    PolicyRuleMultiSelect,
  },
  inject: ['softwareLicenses'],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    licenseStates: s__('ScanResultPolicy|license states'),
    matchTypeToggleText: s__('ScanResultPolicy|matching type'),
    licenseType: s__('ScanResultPolicy|license type'),
    licenseScanResultRuleCopy: s__(
      'ScanResultPolicy|finds any license %{matchType} %{licenseType} and is %{licenseStates} in an open merge request targeting %{branches}',
    ),
  },
  matchTypeOptions: [
    {
      value: 'true',
      text: s__('ScanResultPolicy|matching'),
    },
    {
      value: 'false',
      text: s__('ScanResultPolicy|except'),
    },
  ],
  licenseStates: {
    newly_detected: s__('ScanResultPolicy|Newly Detected'),
    pre_existing: s__('ScanResultPolicy|Pre-existing'),
  },
  data() {
    return { searchTerm: '' };
  },
  computed: {
    toggleText() {
      let toggleText = this.$options.i18n.licenseType;
      const selectedValues = Array.isArray(this.licenseTypes)
        ? this.licenseTypes
        : [this.licenseTypes];

      if (selectedValues.length === 1) {
        toggleText = this.parsedKnownLicenses.find(({ value }) => value === selectedValues[0]).text;
      }

      if (selectedValues.length > 1) {
        toggleText = sprintf(s__('ScanResultPolicy|%{count} licenses'), {
          count: selectedValues.length,
        });
      }

      return toggleText;
    },
    matchTypeToggleText() {
      return this.matchType ? '' : this.$options.i18n.matchTypeToggleText;
    },
    matchType: {
      get() {
        return this.initRule.match_on_inclusion?.toString();
      },
      set(value) {
        this.triggerChanged({ match_on_inclusion: parseBoolean(value) });
      },
    },
    licenseStates: {
      get() {
        return this.initRule.license_states;
      },
      set(values) {
        this.triggerChanged({ license_states: values });
      },
    },
    licenseTypes: {
      get() {
        return this.initRule.license_types;
      },
      set(values) {
        this.triggerChanged({ license_types: values });
      },
    },
    parsedKnownLicenses() {
      return JSON.parse(this.softwareLicenses).map((license) => {
        return { value: license, text: license };
      });
    },
    filteredLicenses() {
      if (this.searchTerm) {
        return this.parsedKnownLicenses.filter(({ value }) => {
          return value.toLowerCase().includes(this.searchTerm.toLowerCase());
        });
      }

      return this.parsedKnownLicenses;
    },
  },
  methods: {
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
    filterList(searchTerm) {
      this.searchTerm = searchTerm;
    },
  },
};
</script>

<template>
  <div class="gl-line-height-42 gl-display-inline! gl-vertical-align-middle">
    <gl-sprintf :message="$options.i18n.licenseScanResultRuleCopy">
      <template #matchType>
        <gl-collapsible-listbox
          id="matchType"
          v-model="matchType"
          class="gl-display-inline! gl-mx-3 gl-w-auto gl-vertical-align-middle"
          :items="$options.matchTypeOptions"
          :toggle-text="matchTypeToggleText"
          data-testid="match-type-select"
        />
      </template>

      <template #licenseStates>
        <policy-rule-multi-select
          v-model="licenseStates"
          class="gl-mx-3 gl-display-inline! gl-vertical-align-middle"
          :item-type-name="$options.i18n.licenseStates"
          :items="$options.licenseStates"
          data-testid="license-state-select"
        />
      </template>

      <template #licenseType>
        <gl-collapsible-listbox
          v-model="licenseTypes"
          class="gl-vertical-align-middle gl-display-inline!"
          :items="filteredLicenses"
          :toggle-text="toggleText"
          searchable
          multiple
          data-testid="license-multi-select"
          @search="filterList"
        />
      </template>

      <template #branches>
        <policy-rule-branch-selection :init-rule="initRule" @changed="triggerChanged" />
      </template>
    </gl-sprintf>
  </div>
</template>
