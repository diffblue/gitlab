<script>
import { GlLink } from '@gitlab/ui';
import {
  fromYaml,
  humanizeActions,
  humanizeRules,
} from '../policy_editor/scan_execution_policy/lib';
import BasePolicy from './base_policy.vue';
import PolicyInfoRow from './policy_info_row.vue';

export default {
  components: {
    GlLink,
    BasePolicy,
    PolicyInfoRow,
  },
  props: {
    policy: {
      type: Object,
      required: true,
    },
  },
  computed: {
    humanizedActions() {
      return humanizeActions(this.parsedYaml.actions);
    },
    humanizedRules() {
      return humanizeRules(this.parsedYaml.rules);
    },
    parsedYaml() {
      try {
        return fromYaml(this.policy.yaml);
      } catch (e) {
        return null;
      }
    },
  },
};
</script>

<template>
  <base-policy :policy="policy">
    <template #type>{{ s__('SecurityOrchestration|Scan execution') }}</template>

    <template #default="{ enforcementStatusLabel }">
      <div v-if="parsedYaml">
        <policy-info-row
          v-if="parsedYaml.description"
          data-testid="policy-description"
          :label="s__('SecurityOrchestration|Description')"
        >
          {{ parsedYaml.description }}
        </policy-info-row>

        <policy-info-row data-testid="policy-rules" :label="s__('SecurityOrchestration|Rule')">
          <p v-for="rule in humanizedRules" :key="rule">{{ rule }}</p>
        </policy-info-row>

        <policy-info-row data-testid="policy-actions" :label="s__('SecurityOrchestration|Action')">
          <p v-for="action in humanizedActions" :key="action">{{ action }}</p>
        </policy-info-row>

        <policy-info-row :label="s__('SecurityOrchestration|Enforcement Status')">
          {{ enforcementStatusLabel }}
        </policy-info-row>

        <policy-info-row
          v-if="policy.latestScan"
          data-testid="policy-latest-scan"
          :label="s__('SecurityOrchestration|Latest scan')"
        >
          {{ policy.latestScan.date }}
          <gl-link :href="policy.latestScan.pipelineUrl">
            {{ s__('SecurityOrchestration|view results') }}
          </gl-link></policy-info-row
        >
      </div>
    </template>
  </base-policy>
</template>
