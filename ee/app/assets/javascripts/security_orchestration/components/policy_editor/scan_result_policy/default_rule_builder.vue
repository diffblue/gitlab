<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BranchExceptionSelector from '../branch_exception_selector.vue';
import ScanFilterSelector from '../scan_filter_selector.vue';
import { SCAN_RESULT_BRANCH_TYPE_OPTIONS } from '../constants';
import { getDefaultRule } from './lib';
import BaseLayoutComponent from './base_layout/base_layout_component.vue';
import PolicyRuleBranchSelection from './policy_rule_branch_selection.vue';
import ScanTypeSelect from './base_layout/scan_type_select.vue';

export default {
  emptyRuleCopy: s__(
    'ScanResultPolicy|When %{scanners} find scanner specified conditions in an open merge request targeting the %{branches} %{branchExceptions} and match %{boldDescription} of the following criteria',
  ),
  i18n: {
    tooltipFilterDisabledTitle: s__('ScanResultPolicy|Select a scan type before adding criteria'),
  },
  name: 'DefaultRuleBuilder',
  components: {
    BranchExceptionSelector,
    BaseLayoutComponent,
    GlSprintf,
    PolicyRuleBranchSelection,
    ScanTypeSelect,
    ScanFilterSelector,
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
    return {
      selectedBranches: [],
      selectedBranchType: null,
      selectedExceptions: [],
    };
  },
  computed: {
    branchExceptions() {
      return this.initRule.branch_exceptions;
    },
    isProject() {
      return this.namespaceType === NAMESPACE_TYPES.PROJECT;
    },
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

      if (this.selectedExceptions.length > 0) {
        rule.branch_exceptions = this.selectedExceptions;
      }

      this.$emit('set-scan-type', rule);
    },
    setBranchType({ branch_type: branchType }) {
      this.selectedBranchType = branchType;
    },
    setSelectedBranches({ branches }) {
      this.selectedBranches = branches;
    },
    setSelectedExceptions({ branch_exceptions: branchExceptions }) {
      this.selectedExceptions = branchExceptions;
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

              <template #branchExceptions>
                <branch-exception-selector
                  v-if="isProject && glFeatures.securityPoliciesBranchExceptions"
                  :selected-exceptions="selectedExceptions"
                  @select="setSelectedExceptions"
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
