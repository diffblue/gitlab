<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  fromYaml,
  humanizeActions,
  humanizeRules,
} from '../policy_editor/scan_execution_policy/lib';
import { SUMMARY_TITLE } from './constants';
import PolicyDrawerLayout from './policy_drawer_layout.vue';
import PolicyInfoRow from './policy_info_row.vue';

export default {
  i18n: {
    multipleActionMessage: s__('SecurityOrchestration|Runs %{actions} and %{lastAction} scans'),
    noActionMessage: s__('SecurityOrchestration|No actions defined - policy will not run.'),
    singleActionMessage: s__(`SecurityOrchestration|Runs a %{action} scan`),
    scanExecution: s__('SecurityOrchestration|Scan execution'),
    summary: SUMMARY_TITLE,
  },
  components: {
    GlSprintf,
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
      <policy-info-row data-testid="policy-summary" :label="$options.i18n.summary">
        <p>
          <template v-if="!humanizedActions.length">{{ $options.i18n.noActionMessage }}</template>
          <gl-sprintf
            v-else-if="humanizedActions.length === 1"
            :message="$options.i18n.singleActionMessage"
          >
            <template #action>
              <strong>{{ humanizedActions[0] }}</strong>
            </template>
          </gl-sprintf>
          <gl-sprintf v-else :message="$options.i18n.multipleActionMessage">
            <template #actions>
              <strong>{{ humanizedActions.slice(0, -1).join(', ') }}</strong>
            </template>
            <template #lastAction>
              <strong>{{ humanizedActions[humanizedActions.length - 1] }}</strong>
            </template>
          </gl-sprintf>
        </p>
        <ul>
          <li v-for="(rule, idx) in humanizedRules" :key="idx">
            {{ rule }}
          </li>
        </ul>
      </policy-info-row>
    </template>
  </policy-drawer-layout>
</template>
