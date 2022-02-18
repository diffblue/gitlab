<script>
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
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
    summary: SUMMARY_TITLE,
    scanExecution: s__('SecurityOrchestration|Scan execution'),
  },
  components: {
    PolicyDrawerLayout,
    PolicyInfoRow,
  },
  directives: {
    SafeHtml,
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
        <p v-safe-html="humanizedActions"></p>
        <ul>
          <li v-for="(rule, idx) in humanizedRules" :key="idx">
            {{ rule }}
          </li>
        </ul>
      </policy-info-row>
    </template>
  </policy-drawer-layout>
</template>
