<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { ANY_MERGE_REQUEST, SCAN_FINDING, LICENSE_FINDING } from '../lib';
import AnyMergeRequestRuleBuilder from './any_merge_request_rule_builder.vue';
import SecurityScanRuleBuilder from './security_scan_rule_builder.vue';
import LicenseScanRuleBuilder from './license_scan_rule_builder.vue';
import DefaultRuleBuilder from './default_rule_builder.vue';

export default {
  components: {
    GlAlert,
    GlSprintf,
    DefaultRuleBuilder,
    AnyMergeRequestRuleBuilder,
    SecurityScanRuleBuilder,
    LicenseScanRuleBuilder,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    initRule: {
      type: Object,
      required: true,
    },
  },
  data() {
    const previousRules = {
      [ANY_MERGE_REQUEST]: null,
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
      error: null,
    };
  },
  computed: {
    isAnyMergeRequestRule() {
      return this.initRule.type === ANY_MERGE_REQUEST;
    },
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
    handleError(error) {
      this.error = error;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" :dismissible="false" class="gl-mb-3" variant="danger">
      <gl-sprintf :message="error">
        <template #bold="{ content }">
          <span class="font-weight-bold">{{ content }}</span>
        </template>
      </gl-sprintf>
    </gl-alert>

    <default-rule-builder
      v-if="isEmptyRule"
      :init-rule="initRule"
      @error="handleError"
      @changed="updateRule"
      @remove="removeRule"
      @set-scan-type="setScanType"
    />

    <any-merge-request-rule-builder
      v-else-if="isAnyMergeRequestRule && glFeatures.scanResultAnyMergeRequest"
      :init-rule="initRule"
      @changed="updateRule"
      @remove="removeRule"
      @set-scan-type="setScanType"
    />

    <security-scan-rule-builder
      v-else-if="isSecurityRule"
      :init-rule="initRule"
      @error="handleError"
      @changed="updateRule"
      @remove="removeRule"
      @set-scan-type="setScanType"
    />

    <license-scan-rule-builder
      v-else-if="isLicenseRule"
      :init-rule="initRule"
      @error="handleError"
      @changed="updateRule"
      @remove="removeRule"
      @set-scan-type="setScanType"
    />
  </div>
</template>
