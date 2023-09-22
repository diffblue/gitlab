<script>
import { xor, isEmpty } from 'lodash';
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { REPORT_TYPES_DEFAULT, SEVERITY_LEVELS } from 'ee/security_dashboard/store/constants';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BranchExceptionSelector from '../../branch_exception_selector.vue';
import {
  ANY_OPERATOR,
  BRANCH_EXCEPTIONS_KEY,
  GREATER_THAN_OPERATOR,
  VULNERABILITIES_ALLOWED_OPERATORS,
  SCAN_RESULT_BRANCH_TYPE_OPTIONS,
} from '../../constants';
import { enforceIntValue } from '../../utils';
import ScanFilterSelector from '../../scan_filter_selector.vue';
import RuleMultiSelect from '../../rule_multi_select.vue';
import SectionLayout from '../../section_layout.vue';
import { getDefaultRule, groupVulnerabilityStatesWithDefaults } from '../lib';
import SeverityFilter from './scan_filters/severity_filter.vue';
import AgeFilter from './scan_filters/age_filter.vue';
import StatusFilters from './scan_filters/status_filters.vue';
import AttributeFilters from './scan_filters/attribute_filters.vue';
import BranchSelection from './branch_selection.vue';
import {
  FILTERS,
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
  SEVERITY,
  STATUS,
  ATTRIBUTE,
  FIX_AVAILABLE,
  FALSE_POSITIVE,
  AGE,
  AGE_TOOLTIP_NO_PREVIOUSLY_EXISTING_VULNERABILITY,
  AGE_TOOLTIP_MAXIMUM_REACHED,
  DEFAULT_VULNERABILITY_STATES,
} from './scan_filters/constants';
import NumberRangeSelect from './number_range_select.vue';
import ScanTypeSelect from './scan_type_select.vue';

export default {
  FILTERS,
  SEVERITY,
  STATUS,
  AGE,
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
  ATTRIBUTE,
  scanResultRuleCopy: s__(
    'ScanResultPolicy|When %{scanType} %{scanners} runs against the %{branches} %{branchExceptions} and find(s) %{vulnerabilitiesNumber} %{boldDescription} of the following criteria:',
  ),
  components: {
    BranchExceptionSelector,
    SectionLayout,
    GlSprintf,
    BranchSelection,
    RuleMultiSelect,
    ScanFilterSelector,
    ScanTypeSelect,
    SeverityFilter,
    AgeFilter,
    StatusFilters,
    AttributeFilters,
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
    const {
      vulnerability_age: vulnerabilityAge,
      vulnerability_states: vulnerabilityStates,
    } = this.initRule;
    const vulnerabilityStateGroups = groupVulnerabilityStatesWithDefaults(vulnerabilityStates);
    const vulnerabilityAttributes = this.initRule.vulnerability_attributes || {};

    const filters = {
      [AGE]: !isEmpty(vulnerabilityAge),
      [NEWLY_DETECTED]:
        Boolean(vulnerabilityStateGroups[NEWLY_DETECTED]) || isEmpty(vulnerabilityStateGroups),
      [PREVIOUSLY_EXISTING]: Boolean(vulnerabilityStateGroups[PREVIOUSLY_EXISTING]),
      [FALSE_POSITIVE]: vulnerabilityAttributes[FALSE_POSITIVE] !== undefined,
      [FIX_AVAILABLE]: vulnerabilityAttributes[FIX_AVAILABLE] !== undefined,
    };
    filters[STATUS] = Boolean(filters[NEWLY_DETECTED] && filters[PREVIOUSLY_EXISTING]);
    filters[ATTRIBUTE] = Boolean(filters[FALSE_POSITIVE] && filters[FIX_AVAILABLE]);

    return {
      filters,
    };
  },
  computed: {
    isProject() {
      return this.namespaceType === NAMESPACE_TYPES.PROJECT;
    },
    severityLevels: {
      get() {
        const { severity_levels: severityLevels = [] } = this.initRule;

        if (!Array.isArray(severityLevels)) {
          return [];
        }

        return severityLevels.length === 0
          ? Object.keys(this.$options.SEVERITY_LEVELS)
          : severityLevels;
      },
      set(value) {
        const numberOfPossibleLevels = Object.keys(this.$options.SEVERITY_LEVELS).length;
        const newValue = value?.length === numberOfPossibleLevels ? [] : value;
        this.triggerChanged({ severity_levels: newValue });
      },
    },
    vulnerabilityStates: {
      get() {
        const vulnerabilityStateGroups = groupVulnerabilityStatesWithDefaults(
          this.initRule.vulnerability_states,
        );
        return {
          [PREVIOUSLY_EXISTING]: vulnerabilityStateGroups[PREVIOUSLY_EXISTING],
          [NEWLY_DETECTED]: vulnerabilityStateGroups[NEWLY_DETECTED],
        };
      },
      set(values) {
        const states = [...(values[NEWLY_DETECTED] || []), ...(values[PREVIOUSLY_EXISTING] || [])];
        if (!states.length) {
          this.triggerChanged({ vulnerability_states: null });
          return;
        }

        const statesMatchDefault = xor([...states], [...DEFAULT_VULNERABILITY_STATES]).length === 0;
        this.triggerChanged({
          vulnerability_states: statesMatchDefault ? [] : states,
        });
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
    vulnerabilityAttributes: {
      get() {
        return this.initRule.vulnerability_attributes || {};
      },
      set(value) {
        this.filters = {
          ...this.filters,
          [FALSE_POSITIVE]: value[FALSE_POSITIVE] !== undefined,
          [FIX_AVAILABLE]: value[FIX_AVAILABLE] !== undefined,
        };
        this.updateCombinedFilters();
        if (!Object.keys(value).length) {
          this.removeFilterFromRule('vulnerability_attributes');
        } else {
          this.triggerChanged({ vulnerability_attributes: value });
        }
      },
    },
    isStatusFilterSelected() {
      return (
        this.isFilterSelected(this.$options.NEWLY_DETECTED) ||
        this.isFilterSelected(this.$options.PREVIOUSLY_EXISTING)
      );
    },
    isAttributeFilterSelected() {
      return this.isFilterSelected(FIX_AVAILABLE) || this.isFilterSelected(FALSE_POSITIVE);
    },
    selectedVulnerabilitiesOperator() {
      return this.vulnerabilitiesAllowed === 0 ? ANY_OPERATOR : GREATER_THAN_OPERATOR;
    },
  },
  watch: {
    filters: {
      handler() {
        if (!this.vulnerabilityStates[PREVIOUSLY_EXISTING]?.length && this.isFilterSelected(AGE)) {
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
        this.filters[statusKey] = true;
        this.updateCombinedFilters();
      } else if (filter === ATTRIBUTE) {
        const attributeKey =
          Object.keys(this.vulnerabilityAttributes)[0] === FIX_AVAILABLE
            ? FALSE_POSITIVE
            : FIX_AVAILABLE;
        this.vulnerabilityAttributes = {
          ...this.vulnerabilityAttributes,
          [attributeKey]: true,
        };
      } else {
        this.filters[filter] = [];
      }
    },
    setScanType(value) {
      const rule = getDefaultRule(value);
      this.$emit('set-scan-type', rule);
    },
    removeAgeFilter() {
      this.filters[AGE] = false;
      this.vulnerabilityAge = null;
    },
    removeStatusFilter(filter) {
      this.filters = {
        ...this.filters,
        [filter]: false,
      };
      this.vulnerabilityStates = {
        ...this.vulnerabilityStates,
        [filter]: null,
      };
      this.updateCombinedFilters();
    },
    removeAttributesFilter(attribute) {
      const { [attribute]: deletedAttribute, ...otherAttributes } = this.vulnerabilityAttributes;
      this.vulnerabilityAttributes = otherAttributes;
    },
    updateCombinedFilters() {
      this.filters = {
        ...this.filters,
        [STATUS]: Boolean(this.filters[NEWLY_DETECTED] && this.filters[PREVIOUSLY_EXISTING]),
        [ATTRIBUTE]: this.filters[FIX_AVAILABLE] && this.filters[FALSE_POSITIVE],
      };
    },
    changeStatusGroup(states) {
      this.filters = {
        ...this.filters,
        [NEWLY_DETECTED]: Boolean(states[NEWLY_DETECTED]),
        [PREVIOUSLY_EXISTING]: Boolean(states[PREVIOUSLY_EXISTING]),
      };
      this.vulnerabilityStates = states;
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
    removeExceptions() {
      const rule = { ...this.initRule };
      if (BRANCH_EXCEPTIONS_KEY in rule) {
        delete rule[BRANCH_EXCEPTIONS_KEY];
      }

      this.$emit('changed', rule);
    },
    shouldDisableFilterSelector(filter) {
      if (filter !== AGE) {
        return false;
      }

      return !this.vulnerabilityStates[PREVIOUSLY_EXISTING]?.length;
    },
    customFilterSelectorTooltip(filter) {
      switch (filter.value) {
        case AGE:
          if (!this.vulnerabilityStates[PREVIOUSLY_EXISTING]?.length) {
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
    <section-layout class="gl-pb-0" :show-remove-button="false" @changed="$emit('changed', $event)">
      <template #content>
        <section-layout class="gl-bg-white!" @remove="$emit('remove')">
          <template #content>
            <gl-sprintf :message="$options.scanResultRuleCopy">
              <template #scanType>
                <scan-type-select :scan-type="initRule.type" @select="setScanType" />
              </template>

              <template #scanners>
                <rule-multi-select
                  v-model="scannersToAdd"
                  class="gl-display-inline! gl-vertical-align-middle"
                  :item-type-name="$options.i18n.scanners"
                  :items="$options.REPORT_TYPES_DEFAULT"
                  data-testid="scanners-select"
                  @error="$emit('error', $event)"
                />
              </template>

              <template #branches>
                <branch-selection
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
                  @remove="removeExceptions"
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
        </section-layout>
      </template>
    </section-layout>

    <section-layout class="gl-pt-3" :show-remove-button="false">
      <template #content>
        <severity-filter
          :selected="severityLevels"
          class="gl-bg-white!"
          @input="severityLevels = $event"
        />

        <status-filters
          v-if="isStatusFilterSelected"
          :filters="filters"
          :selected="vulnerabilityStates"
          @remove="removeStatusFilter"
          @change-status-group="changeStatusGroup"
          @input="vulnerabilityStates = $event"
        />

        <age-filter
          v-if="isFilterSelected($options.AGE)"
          :selected="vulnerabilityAge"
          @remove="removeAgeFilter"
          @input="handleVulnerabilityAgeChanges"
        />

        <attribute-filters
          v-if="isAttributeFilterSelected"
          :selected="vulnerabilityAttributes"
          @remove="removeAttributesFilter"
          @input="vulnerabilityAttributes = $event"
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
    </section-layout>
  </div>
</template>
