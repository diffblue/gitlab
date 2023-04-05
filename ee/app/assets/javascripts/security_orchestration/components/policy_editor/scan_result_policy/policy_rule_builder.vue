<script>
import { __ } from '~/locale';
import { SCAN_FINDING, LICENSE_FINDING } from './lib';
import BaseLayoutComponent from './base_layout/base_layout_component.vue';
import SecurityScanRuleBuilder from './security_scan_rule_builder.vue';
import LicenseScanRuleBuilder from './license_scan_rule_builder.vue';

export default {
  components: {
    BaseLayoutComponent,
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
    isEmptyRule() {
      return this.initRule.type === '';
    },
  },
  methods: {
    removeRule() {
      this.$emit('remove');
    },
    updateRule(value) {
      this.$emit('changed', { ...this.initRule, ...value });
    },
  },
  i18n: {
    scanResultIfLabel: __('if'),
  },
};
</script>

<template>
  <base-layout-component
    v-if="isEmptyRule"
    :rule-label="$options.i18n.scanResultIfLabel"
    :show-scan-type-dropdown="true"
    :type="initRule.type"
    @changed="updateRule"
    @remove="removeRule"
  />

  <security-scan-rule-builder
    v-else-if="isSecurityRule"
    :init-rule="initRule"
    :rule-label="$options.i18n.scanResultIfLabel"
    @changed="updateRule"
    @remove="removeRule"
  />

  <license-scan-rule-builder
    v-else-if="isLicenseRule"
    :init-rule="initRule"
    :rule-label="$options.i18n.scanResultIfLabel"
    @changed="updateRule"
    @remove="removeRule"
  />
</template>
