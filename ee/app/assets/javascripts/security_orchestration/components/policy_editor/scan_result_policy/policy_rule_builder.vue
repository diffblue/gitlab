<script>
import { GlSprintf, GlForm, GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getDefaultRule, SCAN_FINDING, LICENSE_FINDING } from './lib';
import SecurityScanRuleBuilder from './security_scan_rule_builder.vue';
import LicenseScanRuleBuilder from './license_scan_rule_builder.vue';

export default {
  scanResultRuleCopy: s__('ScanResultPolicy|%{ifLabelStart}if%{ifLabelEnd} %{selector}'),
  components: {
    GlSprintf,
    GlForm,
    GlButton,
    GlCollapsibleListbox,
    SecurityScanRuleBuilder,
    LicenseScanRuleBuilder,
  },
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isSecurityRule() {
      return this.initRule.type === SCAN_FINDING;
    },
    isLicenseRule() {
      return this.initRule.type === LICENSE_FINDING;
    },
    scanRuleTypeToggleText() {
      return this.scanType ? '' : this.$options.i18n.scanRuleTypeToggleText;
    },
    scanType: {
      get() {
        return this.initRule.type;
      },
      set(value) {
        const rule = getDefaultRule(value);
        this.updateRule(rule);
      },
    },
  },
  methods: {
    removeRule() {
      this.$emit('remove');
    },
    updateRule(values) {
      this.$emit('changed', values);
    },
    triggerChanged(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
  },
  i18n: {
    scanRuleTypeToggleText: s__('SecurityOrchestration|Select scan type'),
  },
  scanTypeOptions: [
    {
      value: SCAN_FINDING,
      text: s__('SecurityOrchestration|Security Scan'),
    },
    {
      value: LICENSE_FINDING,
      text: s__('SecurityOrchestration|License Scan'),
    },
  ],
};
</script>

<template>
  <div class="gl-bg-gray-10 gl-rounded-base gl-pl-5 gl-pr-7 gl-pt-5 gl-relative gl-pb-4">
    <gl-form @submit.prevent>
      <gl-sprintf :message="$options.scanResultRuleCopy">
        <template #ifLabel="{ content }">
          <label for="selector" class="gl-display-inline! text-uppercase gl-font-lg gl-mr-3">{{
            content
          }}</label>
        </template>

        <template #selector>
          <gl-collapsible-listbox
            id="scanType"
            v-model="scanType"
            class="gl-display-inline! gl-w-auto gl-vertical-align-middle"
            :items="$options.scanTypeOptions"
            :toggle-text="scanRuleTypeToggleText"
          />
        </template>
      </gl-sprintf>

      <security-scan-rule-builder
        v-if="isSecurityRule"
        :init-rule="initRule"
        @changed="updateRule"
        @remove="removeRule"
      />

      <license-scan-rule-builder
        v-else-if="isLicenseRule"
        :init-rule="initRule"
        @changed="updateRule"
        @remove="removeRule"
      />
    </gl-form>
    <gl-button
      icon="remove"
      category="tertiary"
      class="gl-absolute gl-top-1 gl-right-1"
      :aria-label="__('Remove')"
      data-testid="remove-rule"
      @click="$emit('remove', $event)"
    />
  </div>
</template>
