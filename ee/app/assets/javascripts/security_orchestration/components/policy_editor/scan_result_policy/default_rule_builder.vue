<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import ScanFilterSelector from '../scan_filter_selector.vue';
import { SCAN_RESULT_BRANCH_TYPE_OPTIONS } from '../constants';
import { getDefaultRule } from './lib';
import BaseLayoutComponent from './base_layout/base_layout_component.vue';
import PolicyRuleBranchSelection from './policy_rule_branch_selection.vue';
import ScanTypeSelect from './base_layout/scan_type_select.vue';

export default {
  emptyRuleCopy: s__(
    'ScanResultPolicy|When %{scanners} find scanner specified conditions in an open merge request targeting the %{branches} and match %{boldDescription} of the following criteria',
  ),
  i18n: {
    tooltipFilterDisabledTitle: s__('ScanResultPolicy|Select a scan type before adding criteria'),
  },
  name: 'DefaultRuleBuilder',
  components: {
    BaseLayoutComponent,
    GlSprintf,
    PolicyRuleBranchSelection,
    ScanTypeSelect,
    ScanFilterSelector,
  },
  inject: ['namespaceType'],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      selectedBranches: [],
      selectedBranchType: null,
    };
  },
  computed: {
    ruleWithSelectedBranchesOnly() {
      return { branches: this.selectedBranches };
    },
    branchTypes() {
      return SCAN_RESULT_BRANCH_TYPE_OPTIONS(this.namespaceType);
    },
  },
  methods: {
    selectScanType(type) {
      const rule = getDefaultRule(type);

      if (this.selectedBranches.length > 0) {
        rule.branches = this.selectedBranches;
        delete rule.branch_type;
      }

      if (this.selectedBranchType) {
        rule.branch_type = this.selectedBranchType;
        delete rule.branches;
      }

      this.$emit('set-scan-type', rule);
    },
    setBranchType({ branch_type: branchType }) {
      this.selectedBranchType = branchType;
    },
    setSelectedBranches({ branches }) {
      this.selectedBranches = branches;
    },
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
            <gl-sprintf :message="$options.emptyRuleCopy">
              <template #scanners>
                <scan-type-select @select="selectScanType" />
              </template>

              <template #branches>
                <policy-rule-branch-selection
                  :init-rule="ruleWithSelectedBranchesOnly"
                  :branch-types="branchTypes"
                  @changed="setSelectedBranches"
                  @set-branch-type="setBranchType"
                  @error="$emit('error', $event)"
                />
              </template>

              <template #boldDescription>
                <b>{{ __('all') }}</b>
              </template>
            </gl-sprintf>
          </template>
        </base-layout-component>
      </template>
    </base-layout-component>
    <base-layout-component class="gl-pt-3" :show-remove-button="false">
      <template #content>
        <scan-filter-selector
          :disabled="true"
          :tooltip-title="$options.i18n.tooltipFilterDisabledTitle"
          class="gl-bg-white! gl-w-full"
        />
      </template>
    </base-layout-component>
  </div>
</template>
