<script>
import { GlLink, GlButton, GlFormGroup } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import Container from '../rules.vue';
import ScanResultPolicy from './scan_result_policy.vue';
import PolicyDetails from './policy_details.vue';

export default {
  i18n: {
    securityApprovals: s__('SecurityOrchestration|Security Approvals'),
    description: s__(
      'SecurityOrchestration|Create more robust vulnerability rules and apply them to all your projects.',
    ),
    learnMore: __('Learn more'),
    noPolicies: s__("SecurityOrchestration|You don't have any security policies yet"),
    createPolicy: s__('SecurityOrchestration|Create security policy'),
  },
  components: {
    Container,
    GlLink,
    GlButton,
    ScanResultPolicy,
    PolicyDetails,
    GlFormGroup,
  },
  inject: ['fullPath', 'newPolicyPath'],
  computed: {
    ...mapState('securityOrchestrationModule', ['scanResultPolicies']),
    policies() {
      return this.scanResultPolicies;
    },
    hasPolicies() {
      return this.policies.length > 0;
    },
  },
  mounted() {
    this.fetchScanResultPolicies({ fullPath: this.fullPath });
  },
  methods: {
    ...mapActions('securityOrchestrationModule', ['fetchScanResultPolicies']),
    selectionChanged(index) {
      this.scanResultPolicies[index].isSelected = !this.scanResultPolicies[index].isSelected;
    },
  },
  scanResultPolicyHelpPagePath: helpPagePath(
    'user/application_security/policies/scan-result-policies',
  ),
};
</script>

<template>
  <gl-form-group :label="$options.i18n.securityApprovals">
    <template #label-description>
      {{ $options.i18n.description }}
      <gl-link :href="$options.scanResultPolicyHelpPagePath" target="_blank">{{
        $options.i18n.learnMore
      }}</gl-link>
    </template>
    <container :rules="policies" class="gl-mt-5!">
      <template #thead="{ name, approvalsRequired, branches }">
        <tr class="gl-display-table-row!">
          <th class="gl-w-half!">{{ name }}</th>
          <th>{{ branches }}</th>
          <th>{{ approvalsRequired }}</th>
          <th></th>
        </tr>
      </template>
      <template #tbody>
        <tr v-if="!hasPolicies">
          <td colspan="4">{{ $options.i18n.noPolicies }}</td>
        </tr>
        <template v-for="(policy, index) in policies" v-else>
          <scan-result-policy
            :key="`${policy.name}-policy`"
            :policy="policy"
            @toggle="selectionChanged(index)"
          />
          <policy-details :key="`${policy.name}-details`" :policy="policy" />
        </template>
        <tr>
          <td colspan="12">
            <gl-button category="secondary" variant="confirm" size="small" :href="newPolicyPath">
              {{ $options.i18n.createPolicy }}
            </gl-button>
          </td>
        </tr>
      </template>
    </container>
  </gl-form-group>
</template>
