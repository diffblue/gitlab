<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BranchExceptionSelector from '../branch_exception_selector.vue';
import ScanFilterSelector from '../scan_filter_selector.vue';
import { SCAN_RESULT_BRANCH_TYPE_OPTIONS } from '../constants';
import RuleMultiSelect from '../rule_multi_select.vue';
import PolicyRuleBranchSelection from './policy_rule_branch_selection.vue';
import ScanTypeSelect from './base_layout/scan_type_select.vue';
import StatusFilter from './scan_filters/status_filter.vue';
import LicenseFilter from './scan_filters/license_filter.vue';
import BaseLayoutComponent from './base_layout/base_layout_component.vue';
import { getDefaultRule, LICENSE_STATES } from './lib/rules';
import { FILTERS, FILTERS_STATUS_INDEX, STATUS } from './scan_filters/constants';

export default {
  FILTERS_ITEMS: [FILTERS[FILTERS_STATUS_INDEX]],
  STATUS,
  components: {
    BranchExceptionSelector,
    BaseLayoutComponent,
    GlSprintf,
    LicenseFilter,
    PolicyRuleBranchSelection,
    RuleMultiSelect,
    ScanFilterSelector,
    ScanTypeSelect,
    StatusFilter,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['namespaceType'],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    licenseStatuses: s__('ScanResultPolicy|license status'),
    licenseScanResultRuleCopy: s__(
      'ScanResultPolicy|When %{scanType} in an open merge request targeting %{branches} %{branchExceptions} and the licenses match all of the following criteria:',
    ),
    tooltipFilterDisabledTitle: s__(
      'ScanResultPolicy|License scanning allows only one criteria: Status',
    ),
  },
  licenseStatuses: LICENSE_STATES,
  computed: {
    isProject() {
      return this.namespaceType === NAMESPACE_TYPES.PROJECT;
    },
    branchExceptions() {
      return this.initRule.branch_exceptions;
    },
    branchTypes() {
      return SCAN_RESULT_BRANCH_TYPE_OPTIONS(this.namespaceType);
    },
    licenseStatuses: {
      get() {
        return this.initRule.license_states;
      },
      set(values) {
        this.triggerChanged({ license_states: values });
      },
    },
  },
  methods: {
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
    setScanType(value) {
      const rule = getDefaultRule(value);
      this.$emit('set-scan-type', rule);
    },
    setBranchType(value) {
      this.$emit('changed', value);
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

              <template #branches>
                <policy-rule-branch-selection
                  :init-rule="initRule"
                  :branch-types="branchTypes"
                  @changed="triggerChanged"
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
            </gl-sprintf>
          </template>
        </base-layout-component>
      </template>
    </base-layout-component>

    <base-layout-component class="gl-pt-3" :show-remove-button="false">
      <template #content>
        <status-filter :show-remove-button="false" class="gl-bg-white!">
          <rule-multi-select
            v-model="licenseStatuses"
            class="gl-display-inline! gl-vertical-align-middle"
            :item-type-name="$options.i18n.licenseStatuses"
            :items="$options.licenseStatuses"
            @error="$emit('error', $event)"
          />
        </status-filter>

        <license-filter class="gl-bg-white!" :init-rule="initRule" @changed="triggerChanged" />

        <scan-filter-selector
          :disabled="true"
          :filters="$options.FILTERS_ITEMS"
          :tooltip-title="$options.i18n.tooltipFilterDisabledTitle"
          class="gl-bg-white gl-w-full"
        />
      </template>
    </base-layout-component>
  </div>
</template>
