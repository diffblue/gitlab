<script>
import { s__ } from '~/locale';
import {
  fromYaml,
  humanizeActions,
  humanizeRules,
} from '../policy_editor/scan_execution_policy/lib';
import PolicyDrawerLayout from './policy_drawer_layout.vue';
import PolicyInfoRow from './policy_info_row.vue';

export default {
  i18n: {
    action: s__('SecurityOrchestration|Action'),
    rule: s__('SecurityOrchestration|Rule'),
    scanExecution: s__('SecurityOrchestration|Scan execution'),
  },
  components: {
    PolicyDrawerLayout,
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
  <policy-drawer-layout
    key="scan_execution_policy"
    :description="parsedYaml.description"
    :policy="policy"
    :type="$options.i18n.scanExecution"
  >
    <template v-if="parsedYaml" #summary>
      <policy-info-row data-testid="policy-rules" :label="$options.i18n.rule">
        <p v-for="rule in humanizedRules" :key="rule">{{ rule }}</p>
      </policy-info-row>

      <policy-info-row data-testid="policy-actions" :label="$options.i18n.action">
        <p v-for="action in humanizedActions" :key="action">{{ action }}</p>
      </policy-info-row>
    </template>
  </policy-drawer-layout>
</template>
