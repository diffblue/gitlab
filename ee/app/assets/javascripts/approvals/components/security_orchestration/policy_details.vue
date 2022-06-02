<script>
import { GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  humanizeRules,
  humanizeAction,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/lib/humanize';

export default {
  i18n: {
    policyDetails: s__('SecurityOrchestration|Edit policy'),
  },
  components: {
    GlLink,
  },
  inject: ['securityPoliciesPath'],
  props: {
    policy: {
      type: Object,
      required: true,
    },
  },
  computed: {
    policyAction() {
      return this.policy.actions.find((action) => action.type === 'require_approval');
    },
    humanizedRules() {
      return humanizeRules(this.policy.rules);
    },
    humanizedAction() {
      return humanizeAction(this.policyAction);
    },
    policyEditPath() {
      return `${this.securityPoliciesPath}/${encodeURIComponent(
        this.policy.name,
      )}/edit?type=scan_result_policy`;
    },
  },
};
</script>

<template>
  <transition name="slide-down">
    <tr v-if="policy.isSelected">
      <td colspan="4" class="gl-border-top-0!">
        <div class="gl-px-5! gl-pb-4">
          <p>{{ humanizedAction }}</p>
          <ul>
            <li v-for="(rule, idx) in humanizedRules" :key="idx">
              {{ rule }}
            </li>
          </ul>
          <gl-link :href="policyEditPath" target="_blank">
            {{ $options.i18n.policyDetails }}
          </gl-link>
        </div>
      </td>
    </tr>
  </transition>
</template>
