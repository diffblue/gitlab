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
        return fromYaml({ manifest: this.policy.yaml });
      } catch (e) {
        return null;
      }
    },
    hasOnlyOneAction() {
      return this.humanizedActions.length === 1;
    },
    hasMultipleActions() {
      return this.humanizedActions.length > 1;
    },
    firstAction() {
      return this.hasOnlyOneAction ? this.humanizedActions[0] : '';
    },
    allButLastActions() {
      return this.hasMultipleActions ? this.humanizedActions.slice(0, -1).join(', ') : '';
    },
    lastAction() {
      return this.hasMultipleActions ? [...this.humanizedActions].pop() : '';
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
          <gl-sprintf v-else-if="hasOnlyOneAction" :message="$options.i18n.singleActionMessage">
            <template #action>
              <gl-sprintf :message="firstAction">
                <template #scanner="{ content }">
                  <strong>{{ content }}</strong>
                </template>
              </gl-sprintf>
            </template>
          </gl-sprintf>
          <gl-sprintf v-else :message="$options.i18n.multipleActionMessage">
            <template #actions>
              <gl-sprintf :message="allButLastActions">
                <template #scanner="{ content }">
                  <strong>{{ content }}</strong>
                </template>
              </gl-sprintf>
            </template>
            <template #lastAction>
              <gl-sprintf :message="lastAction">
                <template #scanner="{ content }">
                  <strong>{{ content }}</strong>
                </template>
              </gl-sprintf>
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
