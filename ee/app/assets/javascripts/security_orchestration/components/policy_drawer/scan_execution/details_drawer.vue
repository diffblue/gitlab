<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { fromYaml } from '../../policy_editor/scan_execution_policy/lib';
import { ACTIONS } from '../../policy_editor/constants';
import { SUMMARY_TITLE } from '../constants';
import InfoRow from '../info_row.vue';
import DrawerLayout from '../drawer_layout.vue';
import Tags from './humanized_actions/tags.vue';
import Variables from './humanized_actions/variables.vue';
import { humanizeActions, humanizeRules } from './utils';

export default {
  i18n: {
    noActionMessage: s__('SecurityOrchestration|No actions defined - policy will not run.'),
    scanExecution: s__('SecurityOrchestration|Scan execution'),
    summary: SUMMARY_TITLE,
    ruleMessage: s__('SecurityOrchestration|And scans to be performed:'),
  },
  HUMANIZED_ACTION_COMPONENTS: {
    [ACTIONS.tags]: Tags,
    [ACTIONS.variables]: Variables,
  },
  components: {
    Tags,
    Variables,
    GlSprintf,
    DrawerLayout,
    InfoRow,
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
  },
  methods: {
    humanizedActionComponent({ action }) {
      return this.$options.HUMANIZED_ACTION_COMPONENTS[action];
    },
  },
};
</script>

<template>
  <drawer-layout
    key="scan_execution_policy"
    :description="parsedYaml.description"
    :policy="policy"
    :type="$options.i18n.scanExecution"
  >
    <template v-if="parsedYaml" #summary>
      <info-row data-testid="policy-summary" :label="$options.i18n.summary">
        <template v-if="!humanizedActions.length">{{ $options.i18n.noActionMessage }}</template>
        <div v-for="{ message, criteriaList } in humanizedActions" :key="message" class="gl-mb-3">
          <gl-sprintf :message="message">
            <template #scanner="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
          <ul class="gl-pl-6">
            <li v-for="criteria in criteriaList" :key="criteria.message" class="gl-mt-3">
              {{ criteria.message }}
              <component :is="humanizedActionComponent(criteria)" :criteria="criteria" />
            </li>
          </ul>
        </div>
        <div class="gl-mb-3">{{ $options.i18n.ruleMessage }}</div>
        <ul>
          <li v-for="(rule, idx) in humanizedRules" :key="idx">
            {{ rule }}
          </li>
        </ul>
      </info-row>
    </template>
  </drawer-layout>
</template>
