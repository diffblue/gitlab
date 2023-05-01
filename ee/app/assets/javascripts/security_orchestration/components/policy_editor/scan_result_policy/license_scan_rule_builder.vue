<script>
import { GlSprintf, GlCollapsibleListbox } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import PolicyRuleBranchSelection from 'ee/security_orchestration/components/policy_editor/scan_result_policy/policy_rule_branch_selection.vue';
import PolicyRuleMultiSelect from 'ee/security_orchestration/components/policy_rule_multi_select.vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import ScanTypeSelect from './base_layout/scan_type_select.vue';
import StatusFilter from './scan_filters/status_filter.vue';
import ScanFilterSelector from './scan_filters/scan_filter_selector.vue';
import BaseLayoutComponent from './base_layout/base_layout_component.vue';
import { EXCEPT, getDefaultRule, LICENSE_STATES, MATCHING } from './lib/rules';
import { FILTERS, FILTERS_STATUS_INDEX, STATUS } from './scan_filters/constants';

export default {
  FILTERS_ITEMS: [FILTERS[FILTERS_STATUS_INDEX]],
  STATUS,
  components: {
    BaseLayoutComponent,
    GlSprintf,
    GlCollapsibleListbox,
    PolicyRuleBranchSelection,
    PolicyRuleMultiSelect,
    ScanFilterSelector,
    ScanTypeSelect,
    StatusFilter,
  },
  inject: ['softwareLicenses'],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    licenseStatuses: s__('ScanResultPolicy|license status'),
    matchTypeToggleText: s__('ScanResultPolicy|matching type'),
    licenseType: s__('ScanResultPolicy|license type'),
    licenseScanResultRuleCopy: s__(
      'ScanResultPolicy|When %{scanType} find any license %{matchType} %{licenseType} in an open merge request targeting the %{branches} and the licences match all of the following criteria',
    ),
    tooltipFilterDisabledTitle: s__(
      'ScanResultPolicy|License scanning allows only one criteria: Status',
    ),
  },
  matchTypeOptions: [
    {
      value: 'true',
      text: MATCHING,
    },
    {
      value: 'false',
      text: EXCEPT,
    },
  ],
  licenseStatuses: LICENSE_STATES,
  data() {
    return {
      addedFilters: [],
      searchTerm: '',
    };
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
    licenseStatuses: {
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
    setScanType(value) {
      const rule = getDefaultRule(value);
      this.$emit('set-scan-type', rule);
    },
  },
};
</script>

<template>
  <div>
    <base-layout-component
      class="gl-pb-0"
      :type="initRule.type"
      :show-scan-type-dropdown="false"
      :show-remove-button="false"
    >
      <template #content>
        <base-layout-component class="gl-bg-white!" :type="initRule.type" @remove="$emit('remove')">
          <template #content>
            <gl-sprintf :message="$options.i18n.licenseScanResultRuleCopy">
              <template #scanType>
                <scan-type-select :scan-type="initRule.type" @select="setScanType" />
              </template>
              <template #matchType>
                <gl-collapsible-listbox
                  id="matchType"
                  v-model="matchType"
                  class="gl-display-inline! gl-w-auto gl-vertical-align-middle"
                  :items="$options.matchTypeOptions"
                  :toggle-text="matchTypeToggleText"
                  data-testid="match-type-select"
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
          </template>
        </base-layout-component>
      </template>
    </base-layout-component>

    <base-layout-component class="gl-pt-3" :show-remove-button="false">
      <template #content>
        <status-filter :selected="licenseTypes" :show-remove-button="false" class="gl-bg-white!">
          <policy-rule-multi-select
            v-model="licenseStatuses"
            class="gl-display-inline! gl-vertical-align-middle"
            :item-type-name="$options.i18n.licenseStatuses"
            :items="$options.licenseStatuses"
            data-testid="license-state-select"
          />
        </status-filter>

        <scan-filter-selector
          :disabled="true"
          :tooltip-title="$options.i18n.tooltipFilterDisabledTitle"
          class="gl-bg-white! gl-w-full"
          :items="$options.FILTERS_ITEMS"
          :selected="addedFilters"
        />
      </template>
    </base-layout-component>
  </div>
</template>
