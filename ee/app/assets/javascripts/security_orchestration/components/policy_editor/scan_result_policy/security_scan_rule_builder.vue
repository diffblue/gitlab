<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { REPORT_TYPES_DEFAULT, SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import BranchExceptionSelector from 'ee/security_orchestration/components/branch_exception_selector.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  ANY_OPERATOR,
  GREATER_THAN_OPERATOR,
  VULNERABILITIES_ALLOWED_OPERATORS,
  SCAN_RESULT_BRANCH_TYPE_OPTIONS,
} from '../constants';
import { enforceIntValue } from '../utils';
import ScanFilterSelector from '../scan_filter_selector.vue';
import PolicyRuleMultiSelect from '../policy_rule_multi_select.vue';
import { getDefaultRule, groupSelectedVulnerabilityStates } from './lib';
import SeverityFilter from './scan_filters/severity_filter.vue';
import AgeFilter from './scan_filters/age_filter.vue';
import StatusFilters from './scan_filters/status_filters.vue';
import BaseLayoutComponent from './base_layout/base_layout_component.vue';
import PolicyRuleBranchSelection from './policy_rule_branch_selection.vue';
import {
  FILTERS,
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
  SEVERITY,
  STATUS,
  AGE,
  AGE_TOOLTIP_NO_PREVIOUSLY_EXISTING_VULNERABILITY,
  AGE_TOOLTIP_MAXIMUM_REACHED,
} from './scan_filters/constants';
import NumberRangeSelect from './number_range_select.vue';
import ScanTypeSelect from './base_layout/scan_type_select.vue';

export default {
  FILTERS,
  SEVERITY,
  STATUS,
  AGE,
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
  scanResultRuleCopy: s__(
    'ScanResultPolicy|When %{scanType} %{scanners} runs against the %{branches} %{branchExceptions} and find(s) %{vulnerabilitiesNumber} %{boldDescription} of the following criteria:',
  ),
  components: {
    BaseLayoutComponent,
    BranchExceptionSelector,
    GlSprintf,
    PolicyRuleBranchSelection,
    PolicyRuleMultiSelect,
    ScanFilterSelector,
    ScanTypeSelect,
    SeverityFilter,
    AgeFilter,
    StatusFilters,
    NumberRangeSelect,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['namespaceType'],
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
    const { vulnerability_age: vulnerabilityAge, severity_levels: severityLevels } = this.initRule;

    const filters = {
      [SEVERITY]: severityLevels.length ? severityLevels : null,
      [AGE]: Object.keys(vulnerabilityAge || {}).length ? vulnerabilityAge : null,
      [NEWLY_DETECTED]: vulnerabilityStateGroups[NEWLY_DETECTED],
      [PREVIOUSLY_EXISTING]: vulnerabilityStateGroups[PREVIOUSLY_EXISTING],
    };
    filters[STATUS] = filters[NEWLY_DETECTED] && filters[PREVIOUSLY_EXISTING] ? [] : null;

    return {
      filters,
    };
  },
  computed: {
    isProject() {
      return this.namespaceType === NAMESPACE_TYPES.PROJECT;
    },
    severityLevelsToAdd: {
      get() {
        return this.initRule.severity_levels;
      },
      set(value) {
        this.triggerChanged({ severity_levels: value });
      },
    },
    branchTypes() {
      return SCAN_RESULT_BRANCH_TYPE_OPTIONS(this.namespaceType);
    },
    branchExceptions() {
      return this.initRule.branch_exceptions;
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
        this.triggerChanged({ vulnerabilities_allowed: value });
      },
    },
    vulnerabilityAge: {
      get() {
        return this.initRule.vulnerability_age;
      },
      set(value) {
        if (!value) {
          this.removeFilterFromRule('vulnerability_age');
        } else {
          this.triggerChanged({ vulnerability_age: value });
        }
      },
    },
    isSeverityFilterSelected() {
      return this.isFilterSelected(this.$options.SEVERITY) || this.severityLevelsToAdd.length > 0;
    },
    isAgeFilterSelected() {
      return this.isFilterSelected(this.$options.AGE) || this.vulnerabilityAge;
    },
    isStatusFilterSelected() {
      return (
        this.isFilterSelected(this.$options.NEWLY_DETECTED) ||
        this.isFilterSelected(this.$options.PREVIOUSLY_EXISTING)
      );
    },
    selectedVulnerabilitiesOperator() {
      return this.vulnerabilitiesAllowed === 0 ? ANY_OPERATOR : GREATER_THAN_OPERATOR;
    },
  },
  watch: {
    filters: {
      handler(value) {
        if (!value[PREVIOUSLY_EXISTING]?.length && this.isFilterSelected(AGE)) {
          this.removeAgeFilter();
        }
      },
      deep: true,
    },
  },
  methods: {
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
    setBranchType(value) {
      this.$emit('changed', value);
    },
    isFilterSelected(filter) {
      return Boolean(this.filters[filter]);
    },
    selectFilter(filter) {
      if (filter === STATUS) {
        const statusKey = this.filters[NEWLY_DETECTED] ? PREVIOUSLY_EXISTING : NEWLY_DETECTED;
        this.filters[statusKey] = [];
        this.filters[STATUS] =
          this.filters[NEWLY_DETECTED] && this.filters[PREVIOUSLY_EXISTING] ? [] : null;
      } else {
        this.filters[filter] = [];
      }
    },
    setScanType(value) {
      const rule = getDefaultRule(value);
      this.$emit('set-scan-type', rule);
    },
    removeSeverityFilter() {
      this.filters[SEVERITY] = null;
      this.emitSeverityFilterChanges();
    },
    removeAgeFilter() {
      this.filters[AGE] = null;
      this.vulnerabilityAge = null;
    },
    removeStatusFilter(filter) {
      this.filters[filter] = null;
      this.updateCombinedFilters();
      this.emitStatusFilterChanges();
    },
    updateCombinedFilters() {
      this.filters[STATUS] =
        this.filters[NEWLY_DETECTED] && this.filters[PREVIOUSLY_EXISTING] ? [] : null;
    },
    removeFilterFromRule(filter) {
      const { [filter]: deletedFilter, ...otherFilters } = this.initRule;
      this.$emit('changed', otherFilters);
    },
    handleVulnerabilitiesAllowedOperatorChange(value) {
      if (value === ANY_OPERATOR) {
        this.vulnerabilitiesAllowed = 0;
      }
    },
    handleVulnerabilityAgeChanges(ageValues) {
      if (ageValues.operator === ANY_OPERATOR) {
        this.vulnerabilityAge = null;
        return;
      }
      this.vulnerabilityAge = { ...this.vulnerabilityAge, ...ageValues };
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
    emitSeverityFilterChanges() {
      const states = [...(this.filters[SEVERITY] || [])];
      this.triggerChanged({ severity_levels: states });
    },
    shouldDisableFilterSelector(filter) {
      if (filter !== AGE) {
        return false;
      }

      return !this.filters[PREVIOUSLY_EXISTING]?.length;
    },
    customFilterSelectorTooltip(filter) {
      switch (filter.value) {
        case AGE:
          if (!this.filters[PREVIOUSLY_EXISTING]?.length) {
            return filter.tooltip[AGE_TOOLTIP_NO_PREVIOUSLY_EXISTING_VULNERABILITY];
          }
          return filter.tooltip[AGE_TOOLTIP_MAXIMUM_REACHED];
        default:
          return '';
      }
    },
  },
  REPORT_TYPES_DEFAULT_KEYS: Object.keys(REPORT_TYPES_DEFAULT),
  REPORT_TYPES_DEFAULT,
  SEVERITY_LEVELS,
  VULNERABILITIES_ALLOWED_OPERATORS,
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
                  @error="$emit('error', $event)"
                />
              </template>

              <template #branches>
                <policy-rule-branch-selection
                  :init-rule="initRule"
                  :branch-types="branchTypes"
                  @changed="triggerChanged($event)"
                  @set-branch-type="setBranchType"
                />
              </template>

              <template #branchExceptions>
                <branch-exception-selector
                  v-if="isProject && glFeatures.securityPoliciesBranchExceptions"
                  :selected-exceptions="branchExceptions"
                  @select="triggerChanged"
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
          @remove="removeSeverityFilter"
          @input="severityLevelsToAdd = $event"
        />

        <status-filters
          v-if="isStatusFilterSelected"
          :selected="filters"
          @remove="removeStatusFilter"
          @input="setStatus"
        />

        <age-filter
          v-if="isAgeFilterSelected"
          :selected="vulnerabilityAge"
          @remove="removeAgeFilter"
          @input="handleVulnerabilityAgeChanges"
        />

        <scan-filter-selector
          class="gl-bg-white! gl-w-full"
          :filters="$options.FILTERS"
          :selected="filters"
          :should-disable-filter="shouldDisableFilterSelector"
          :custom-filter-tooltip="customFilterSelectorTooltip"
          @select="selectFilter"
        />
      </template>
    </base-layout-component>
  </div>
</template>
