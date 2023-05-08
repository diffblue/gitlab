<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { REPORT_TYPES_DEFAULT, SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import PolicyRuleMultiSelect from '../../policy_rule_multi_select.vue';
import { ANY_OPERATOR, MORE_THAN_OPERATOR } from '../constants';
import { enforceIntValue } from '../utils';
import { getDefaultRule, groupSelectedVulnerabilityStates } from './lib';
import SeverityFilter from './scan_filters/severity_filter.vue';
import StatusFilters from './scan_filters/status_filters.vue';
import BaseLayoutComponent from './base_layout/base_layout_component.vue';
import PolicyRuleBranchSelection from './policy_rule_branch_selection.vue';
import ScanFilterSelector from './scan_filters/scan_filter_selector.vue';
import { SEVERITY, STATUS, NEWLY_DETECTED, PREVIOUSLY_EXISTING } from './scan_filters/constants';
import NumberRangeSelect from './number_range_select.vue';
import ScanTypeSelect from './base_layout/scan_type_select.vue';

export default {
  SEVERITY,
  STATUS,
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
  scanResultRuleCopy: s__(
    'ScanResultPolicy|When %{scanType} %{scanners} runs against the %{branches} and find(s) %{vulnerabilitiesNumber} %{boldDescription} of the following criteria:',
  ),
  components: {
    BaseLayoutComponent,
    GlSprintf,
    PolicyRuleBranchSelection,
    PolicyRuleMultiSelect,
    ScanFilterSelector,
    ScanTypeSelect,
    SeverityFilter,
    StatusFilters,
    NumberRangeSelect,
  },
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  data() {
    const vulnerabilityStateGroups = groupSelectedVulnerabilityStates(
      this.initRule.vulnerability_states,
    );
    return {
      filters: {
        [SEVERITY]: this.initRule.severity_levels.length ? this.initRule.severity_levels : null,
        [NEWLY_DETECTED]: vulnerabilityStateGroups[NEWLY_DETECTED],
        [PREVIOUSLY_EXISTING]: vulnerabilityStateGroups[PREVIOUSLY_EXISTING],
      },
    };
  },
  computed: {
    severityLevelsToAdd() {
      return this.initRule.severity_levels;
    },
    vulnerabilityStates() {
      return this.initRule.vulnerability_states;
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
    vulnerabilitiesAllowed: {
      get() {
        return enforceIntValue(this.initRule.vulnerabilities_allowed);
      },
      set(value) {
        this.triggerChanged({ vulnerabilities_allowed: enforceIntValue(value) });
      },
    },
    isSeverityFilterSelected() {
      return this.isFilterSelected(this.$options.SEVERITY) || this.severityLevelsToAdd.length > 0;
    },
    isStatusFilterSelected() {
      return (
        this.isFilterSelected(this.$options.NEWLY_DETECTED) ||
        this.isFilterSelected(this.$options.PREVIOUSLY_EXISTING)
      );
    },
    selectedVulnerabilitiesOperator() {
      return this.vulnerabilitiesAllowed === 0 ? ANY_OPERATOR : MORE_THAN_OPERATOR;
    },
  },
  methods: {
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
    isFilterSelected(filter) {
      return Boolean(this.filters[filter]);
    },
    selectFilter(filter) {
      if (filter === STATUS) {
        const statusKey = this.filters[NEWLY_DETECTED] ? PREVIOUSLY_EXISTING : NEWLY_DETECTED;
        this.filters[statusKey] = [];
      } else {
        this.filters[filter] = [];
      }
    },
    setScanType(value) {
      const rule = getDefaultRule(value);
      this.$emit('set-scan-type', rule);
    },
    removeFilter(filter) {
      this.filters[filter] = null;
      this.emitStatusFilterChanges();
    },
    handleVulnerabilitiesAllowedOperatorChange(value) {
      if (value === ANY_OPERATOR) {
        this.vulnerabilitiesAllowed = 0;
      }
    },
    setStatus(updatedFilters) {
      this.filters = updatedFilters;
      this.emitStatusFilterChanges();
    },
    emitStatusFilterChanges() {
      const states = [
        ...(this.filters[NEWLY_DETECTED] || []),
        ...(this.filters[PREVIOUSLY_EXISTING] || []),
      ];

      this.triggerChanged({ vulnerability_states: states });
    },
  },
  REPORT_TYPES_DEFAULT_KEYS: Object.keys(REPORT_TYPES_DEFAULT),
  REPORT_TYPES_DEFAULT,
  SEVERITY_LEVELS,
  VULNERABILITIES_ALLOWED_OPERATORS: [ANY_OPERATOR, MORE_THAN_OPERATOR],
  i18n: {
    severityLevels: s__('ScanResultPolicy|severity levels'),
    scanners: s__('ScanResultPolicy|scanners'),
    vulnerabilityStates: s__('ScanResultPolicy|vulnerability states'),
    vulnerabilitiesAllowed: s__('ScanResultPolicy|vulnerabilities allowed'),
    vulnerabilityMatchDescription: s__('ScanResultPolicy|vulnerabilities that match all'),
  },
};
</script>

<template>
  <div>
    <base-layout-component
      class="gl-pb-0"
      :type="initRule.type"
      :show-remove-button="false"
      @changed="$emit('changed', $event)"
    >
      <template #content>
        <base-layout-component class="gl-bg-white!" :type="initRule.type" @remove="$emit('remove')">
          <template #content>
            <gl-sprintf :message="$options.scanResultRuleCopy">
              <template #scanType>
                <scan-type-select :scan-type="initRule.type" @select="setScanType" />
              </template>

              <template #scanners>
                <policy-rule-multi-select
                  v-model="scannersToAdd"
                  class="gl-display-inline! gl-vertical-align-middle"
                  :item-type-name="$options.i18n.scanners"
                  :items="$options.REPORT_TYPES_DEFAULT"
                  data-testid="scanners-select"
                />
              </template>

              <template #branches>
                <policy-rule-branch-selection
                  :init-rule="initRule"
                  @changed="triggerChanged($event)"
                />
              </template>

              <template #vulnerabilitiesNumber>
                <number-range-select
                  id="vulnerabilities-allowed"
                  v-model="vulnerabilitiesAllowed"
                  :label="$options.i18n.vulnerabilitiesAllowed"
                  :selected="selectedVulnerabilitiesOperator"
                  :operators="$options.VULNERABILITIES_ALLOWED_OPERATORS"
                  @operator-change="handleVulnerabilitiesAllowedOperatorChange"
                />
              </template>

              <template #boldDescription>
                <b>{{ $options.i18n.vulnerabilityMatchDescription }}</b>
              </template>
            </gl-sprintf>
          </template>
        </base-layout-component>
      </template>
    </base-layout-component>

    <base-layout-component class="gl-pt-3" :show-remove-button="false">
      <template #content>
        <severity-filter
          v-if="isSeverityFilterSelected"
          :selected="severityLevelsToAdd"
          class="gl-bg-white!"
          @remove="removeFilter"
          @input="triggerChanged({ severity_levels: $event })"
        />

        <status-filters
          v-if="isStatusFilterSelected"
          :selected="filters"
          @remove="removeFilter"
          @input="setStatus"
        />

        <scan-filter-selector
          class="gl-bg-white! gl-w-full"
          :selected="filters"
          @select="selectFilter"
        />
      </template>
    </base-layout-component>
  </div>
</template>
