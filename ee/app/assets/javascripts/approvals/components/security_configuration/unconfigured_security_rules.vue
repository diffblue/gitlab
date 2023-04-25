<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { COVERAGE_CHECK_NAME } from 'ee/approvals/constants';
import { s__ } from '~/locale';
import UnconfiguredSecurityRule from './unconfigured_security_rule.vue';

export default {
  components: {
    UnconfiguredSecurityRule,
    GlSkeletonLoader,
  },
  inject: {
    coverageCheckHelpPagePath: {
      default: '',
    },
  },
  computed: {
    ...mapState({
      rules: (state) => state.approvals.rules,
      isApprovalsLoading: (state) => state.approvals.isLoading,
    }),
    isRulesLoading() {
      return this.isApprovalsLoading;
    },
    securityRules() {
      return [
        {
          name: COVERAGE_CHECK_NAME,
          description: s__(
            'SecurityApprovals|Requires approval for decreases in test coverage. %{linkStart}Learn more.%{linkEnd}',
          ),
          docsPath: this.coverageCheckHelpPagePath,
        },
      ];
    },
    unconfiguredRules() {
      return this.securityRules.reduce((filtered, securityRule) => {
        const hasApprovalRuleDefined = this.hasApprovalRuleDefined(securityRule);

        if (!hasApprovalRuleDefined) {
          filtered.push({ ...securityRule });
        }
        return filtered;
      }, []);
    },
  },
  methods: {
    ...mapActions({ openCreateModal: 'createModal/open' }),
    hasApprovalRuleDefined(matchRule) {
      return this.rules.some((rule) => {
        return matchRule.name === rule.name;
      });
    },
  },
};
</script>

<template>
  <table class="table m-0">
    <tbody>
      <tr v-if="isRulesLoading">
        <td colspan="3">
          <gl-skeleton-loader :lines="3" />
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
