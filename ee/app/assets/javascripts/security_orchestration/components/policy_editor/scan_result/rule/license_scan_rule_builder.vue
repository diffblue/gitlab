<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import BranchExceptionSelector from '../../branch_exception_selector.vue';
import ScanFilterSelector from '../../scan_filter_selector.vue';
import { SCAN_RESULT_BRANCH_TYPE_OPTIONS, BRANCH_EXCEPTIONS_KEY } from '../../constants';
import RuleMultiSelect from '../../rule_multi_select.vue';
import SectionLayout from '../../section_layout.vue';
import { getDefaultRule, LICENSE_STATES } from '../lib/rules';
import StatusFilter from './scan_filters/status_filter.vue';
import LicenseFilter from './scan_filters/license_filter.vue';
import { FILTERS, FILTERS_STATUS_INDEX, STATUS } from './scan_filters/constants';
import ScanTypeSelect from './scan_type_select.vue';
import BranchSelection from './branch_selection.vue';

export default {
  FILTERS_ITEMS: [FILTERS[FILTERS_STATUS_INDEX]],
  STATUS,
  components: {
    BranchExceptionSelector,
    SectionLayout,
    GlSprintf,
    LicenseFilter,
    BranchSelection,
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
    removeExceptions() {
      const rule = { ...this.initRule };
      if (BRANCH_EXCEPTIONS_KEY in rule) {
        delete rule[BRANCH_EXCEPTIONS_KEY];
      }

      this.$emit('changed', rule);
    },
  },
};
</script>

<template>
  <div>
    <section-layout class="gl-pb-0" :show-remove-button="false">
      <template #content>
        <section-layout class="gl-bg-white!" @remove="$emit('remove')">
          <template #content>
            <gl-sprintf :message="$options.i18n.licenseScanResultRuleCopy">
              <template #scanType>
                <scan-type-select :scan-type="initRule.type" @select="setScanType" />
              </template>

              <template #branches>
                <branch-selection
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
                  @remove="removeExceptions"
                  @select="triggerChanged"
                />
              </template>
            </gl-sprintf>
          </template>
        </section-layout>
      </template>
    </section-layout>

    <section-layout class="gl-pt-3" :show-remove-button="false">
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
    </section-layout>
  </div>
</template>
