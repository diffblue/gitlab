<script>
import { s__ } from '~/locale';
import { fromYaml, humanizeRules, humanizeAction } from '../policy_editor/scan_result_policy/lib';
import PolicyDrawerLayout from './policy_drawer_layout.vue';
import PolicyInfoRow from './policy_info_row.vue';

export default {
  i18n: {
    action: s__('SecurityOrchestration|Action'),
    rule: s__('SecurityOrchestration|Rule'),
    scanResult: s__('SecurityOrchestration|Scan result'),
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
  <policy-drawer-layout
    key="scan_result_policy"
    :description="parsedYaml.description"
    :policy="policy"
    :type="$options.i18n.scanResult"
  >
    <template v-if="parsedYaml" #summary>
      <policy-info-row data-testid="policy-rules" :label="$options.i18n.rule">
        <p>{{ humanizedAction }}</p>
        <ul>
          <li v-for="(rule, idx) in humanizedRules" :key="idx">
            {{ rule }}
          </li>
        </ul>
      </policy-info-row>
    </template>
  </policy-drawer-layout>
</template>
