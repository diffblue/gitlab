<script>
import { GlCard, GlLink, GlButton, GlIcon, GlFormGroup } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
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
    GlCard,
    GlLink,
    GlButton,
    ScanResultPolicy,
    PolicyDetails,
    GlIcon,
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
  <gl-form-group>
    <gl-card
      class="gl-new-card"
      header-class="gl-new-card-header"
      body-class="gl-new-card-body gl-px-0 gl-overflow-hidden"
    >
      <template #header>
        <div class="gl-new-card-title-wrapper gl-flex-direction-column">
          <h5 class="gl-new-card-title">
            {{ $options.i18n.securityApprovals }}
            <span class="gl-new-card-count">
              <gl-icon name="shield" class="gl-mr-2" />
              {{ policies.length }}
            </span>
          </h5>
          <p class="gl-new-card-description">
            {{ $options.i18n.description }}
            <gl-link
              :href="$options.scanResultPolicyHelpPagePath"
              target="_blank"
              class="gl-font-sm"
              >{{ $options.i18n.learnMore }}.</gl-link
            >
          </p>
        </div>
        <div class="gl-new-card-actions">
          <gl-button category="secondary" size="small" :href="newPolicyPath">
            {{ $options.i18n.createPolicy }}
          </gl-button>
        </div>
      </template>

      <container :rules="policies">
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
            <td colspan="4" class="gl-text-secondary gl-text-center gl-p-5">
              {{ $options.i18n.noPolicies }}.
            </td>
          </tr>
          <template v-for="(policy, index) in policies" v-else>
            <scan-result-policy
              :key="`${policy.name}-policy`"
              :policy="policy"
              @toggle="selectionChanged(index)"
            />
            <policy-details :key="`${policy.name}-details`" :policy="policy" />
          </template>
        </template>
      </container>
    </gl-card>
  </gl-form-group>
</template>
