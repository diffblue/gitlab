<script>
import { s__ } from '~/locale';
import { fromYaml, humanizeRules, humanizeAction } from '../policy_editor/scan_result_policy/lib';
import BasePolicy from './base_policy.vue';
import PolicyInfoRow from './policy_info_row.vue';

export default {
  i18n: {
    action: s__('SecurityOrchestration|Action'),
    description: s__('SecurityOrchestration|Description'),
    rule: s__('SecurityOrchestration|Rule'),
    scanResult: s__('SecurityOrchestration|Scan result'),
    status: s__('SecurityOrchestration|Status'),
  },
  components: {
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
    humanizedRules() {
      return humanizeRules(this.parsedYaml.rules);
    },
    humanizedAction() {
      return humanizeAction(this.requireApproval(this.parsedYaml.actions));
    },
    parsedYaml() {
      try {
        return fromYaml(this.policy.yaml);
      } catch (e) {
        return null;
      }
    },
  },
  methods: {
    requireApproval(actions) {
      return actions.find((action) => action.type === 'require_approval');
    },
  },
};
</script>

<template>
  <base-policy :policy="policy">
    <template #type>{{ $options.i18n.scanResult }}</template>

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
          <p>{{ humanizedAction }}</p>
          <ul>
            <li v-for="(rule, idx) in humanizedRules" :key="idx">
              {{ rule }}
            </li>
          </ul>
        </policy-info-row>

        <policy-info-row :label="$options.i18n.status">
          {{ statusLabel }}
        </policy-info-row>
      </div>
    </template>
  </base-policy>
</template>
