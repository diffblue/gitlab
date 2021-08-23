<script>
import { GlDeprecatedSkeletonLoading as GlSkeletonLoading } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import {
  LICENSE_CHECK_NAME,
  VULNERABILITY_CHECK_NAME,
  LICENSE_SCANNING,
  COVERAGE_CHECK_NAME,
} from 'ee/approvals/constants';
import { s__ } from '~/locale';
import UnconfiguredSecurityRule from './unconfigured_security_rule.vue';

export default {
  components: {
    UnconfiguredSecurityRule,
    GlSkeletonLoading,
  },
  inject: {
    vulnerabilityCheckHelpPagePath: {
      default: '',
    },
    licenseCheckHelpPagePath: {
      default: '',
    },
    coverageCheckHelpPagePath: {
      default: '',
    },
  },
  computed: {
    ...mapState('securityConfiguration', ['configuration']),
    ...mapState({
      rules: (state) => state.approvals.rules,
      isApprovalsLoading: (state) => state.approvals.isLoading,
      isSecurityConfigurationLoading: (state) => state.securityConfiguration.isLoading,
    }),
    isRulesLoading() {
      return this.isApprovalsLoading || this.isSecurityConfigurationLoading;
    },
    securityRules() {
      return [
        {
          name: VULNERABILITY_CHECK_NAME,
          description: s__(
            'SecurityApprovals|Configurable if security scanners are enabled. %{linkStart}Learn more.%{linkEnd}',
          ),
          enableDescription: s__(
            'SecurityApprovals|Requires approval for vulnerabilities. %{linkStart}Learn more.%{linkEnd}',
          ),
          docsPath: this.vulnerabilityCheckHelpPagePath,
        },
        {
          name: LICENSE_CHECK_NAME,
          description: s__(
            'SecurityApprovals|License Scanning must be enabled. %{linkStart}Learn more%{linkEnd}.',
          ),
          enableDescription: s__(
            'SecurityApprovals|Requires approval for Denied licenses. %{linkStart}More information%{linkEnd}',
          ),
          docsPath: this.licenseCheckHelpPagePath,
        },
        {
          name: COVERAGE_CHECK_NAME,
          description: s__(
            'SecurityApprovals|Test coverage must be enabled. %{linkStart}Learn more%{linkEnd}.',
          ),
          enableDescription: s__(
            'SecurityApprovals|Requires approval for decreases in test coverage. %{linkStart}More information%{linkEnd}',
          ),
          docsPath: this.coverageCheckHelpPagePath,
        },
      ];
    },
    unconfiguredRules() {
      return this.securityRules.reduce((filtered, securityRule) => {
        const hasApprovalRuleDefined = this.hasApprovalRuleDefined(securityRule);
        const hasConfiguredJob = this.hasConfiguredJob(securityRule);

        if (!hasApprovalRuleDefined || !hasConfiguredJob) {
          filtered.push({ ...securityRule, hasConfiguredJob });
        }
        return filtered;
      }, []);
    },
  },
  created() {
    this.fetchSecurityConfiguration();
  },
  methods: {
    ...mapActions('securityConfiguration', ['fetchSecurityConfiguration']),
    ...mapActions({ openCreateModal: 'createModal/open' }),
    hasApprovalRuleDefined(matchRule) {
      return this.rules.some((rule) => {
        return matchRule.name === rule.name;
      });
    },
    hasConfiguredJob(matchRule) {
      const { features = [] } = this.configuration;
      return (
        matchRule.name !== LICENSE_CHECK_NAME ||
        features.some((feature) => {
          return feature.type === LICENSE_SCANNING && feature.configured;
        })
      );
    },
  },
};
</script>

<template>
  <table class="table m-0">
    <tbody>
      <tr v-if="isRulesLoading">
        <td colspan="3">
          <gl-skeleton-loading :lines="3" />
        </td>
      </tr>

      <unconfigured-security-rule
        v-for="rule in unconfiguredRules"
        v-else
        :key="rule.name"
        :rule="rule"
        @enable="openCreateModal({ defaultRuleName: rule.name })"
      />
    </tbody>
  </table>
</template>
