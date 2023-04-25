<script>
import { SCAN_FINDING, LICENSE_FINDING } from './lib';
import SecurityScanRuleBuilder from './security_scan_rule_builder.vue';
import LicenseScanRuleBuilder from './license_scan_rule_builder.vue';
import DefaultRuleBuilder from './default_rule_builder.vue';

export default {
  components: {
    DefaultRuleBuilder,
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
      this.$emit('changed', value);
    },
  },
};
</script>

<template>
  <default-rule-builder
    v-if="isEmptyRule"
    :init-rule="initRule"
    @changed="updateRule"
    @remove="removeRule"
  />

  <security-scan-rule-builder
    v-else-if="isSecurityRule"
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
</template>
