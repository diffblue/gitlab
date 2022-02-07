<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  fromYaml,
  humanizeActions,
  humanizeRules,
} from '../policy_editor/scan_execution_policy/lib';
import BasePolicy from './base_policy.vue';
import PolicyInfoRow from './policy_info_row.vue';

export default {
  i18n: {
    action: s__('SecurityOrchestration|Action'),
    description: s__('SecurityOrchestration|Description'),
    latestScan: s__('SecurityOrchestration|Latest scan'),
    rule: s__('SecurityOrchestration|Rule'),
    scanExecution: s__('SecurityOrchestration|Scan execution'),
    status: s__('SecurityOrchestration|Status'),
    viewResults: s__('SecurityOrchestration|view results'),
  },
  components: {
    GlIcon,
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
    <template #type>{{ $options.i18n.scanExecution }}</template>

    <template #default="{ statusLabel }">
      <div v-if="parsedYaml">
        <policy-info-row
          v-if="parsedYaml.description"
          data-testid="policy-description"
          :label="$options.i18n.description"
        >
          {{ parsedYaml.description }}
        </policy-info-row>

        <policy-info-row data-testid="policy-rules" :label="$options.i18n.rule">
          <p v-for="rule in humanizedRules" :key="rule">{{ rule }}</p>
        </policy-info-row>

        <policy-info-row data-testid="policy-actions" :label="$options.i18n.action">
          <p v-for="action in humanizedActions" :key="action">{{ action }}</p>
        </policy-info-row>

        <policy-info-row :label="$options.i18n.status">
          <div v-if="policy.enabled" class="gl-text-green-500" data-testid="enabled-status-text">
            <gl-icon name="check-circle-filled" class="gl-mr-3" />{{ statusLabel }}
          </div>
          <div v-else class="gl-text-gray-500" data-testid="not-enabled-status-text">
            {{ statusLabel }}
          </div>
        </policy-info-row>

        <policy-info-row
          v-if="policy.latestScan"
          data-testid="policy-latest-scan"
          :label="$options.i18n.latestScan"
        >
          {{ policy.latestScan.date }}
          <gl-link :href="policy.latestScan.pipelineUrl">
            {{ $options.i18n.viewResults }}
          </gl-link></policy-info-row
        >
      </div>
    </template>
  </base-policy>
</template>
