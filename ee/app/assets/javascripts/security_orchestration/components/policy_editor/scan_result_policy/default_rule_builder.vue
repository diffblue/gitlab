<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getDefaultRule } from './lib';
import ScanFilterSelector from './scan_filters/scan_filter_selector.vue';
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
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      selectedBranches: [],
    };
  },
  methods: {
    selectScanType(type) {
      const rule = getDefaultRule(type);
      rule.branches = this.selectedBranches;

      this.$emit('changed', rule);
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
                  :init-rule="initRule"
                  @changed="setSelectedBranches"
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
