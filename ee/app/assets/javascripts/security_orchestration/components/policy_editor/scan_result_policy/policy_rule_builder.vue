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
  data() {
    const previousRules = {
      [SCAN_FINDING]: null,
      [LICENSE_FINDING]: null,
    };

    /**
     * Case for existing initRule
     * Or updates from yaml editor
     */
    if (this.initRule.type) {
      previousRules[this.initRule.type] = { ...this.initRule };
    }

    return {
      previousRules,
    };
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
    updateRule(rule) {
      this.$emit('changed', rule);
    },
    setScanType(rule) {
      const { type: previousType } = this.initRule;

      if (previousType) {
        this.previousRules[previousType] = this.initRule;
      }

      const value = this.previousRules[rule.type] || rule;
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
    @set-scan-type="setScanType"
  />

  <security-scan-rule-builder
    v-else-if="isSecurityRule"
    :init-rule="initRule"
    @changed="updateRule"
    @remove="removeRule"
    @set-scan-type="setScanType"
  />

  <license-scan-rule-builder
    v-else-if="isLicenseRule"
    :init-rule="initRule"
    @changed="updateRule"
    @remove="removeRule"
    @set-scan-type="setScanType"
  />
</template>
