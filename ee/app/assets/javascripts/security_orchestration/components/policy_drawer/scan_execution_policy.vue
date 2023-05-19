<script>
import { GlBadge, GlSprintf } from '@gitlab/ui';
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
    noActionMessage: s__('SecurityOrchestration|No actions defined - policy will not run.'),
    scanExecution: s__('SecurityOrchestration|Scan execution'),
    summary: SUMMARY_TITLE,
    ruleMessage: s__('SecurityOrchestration|And scans to be performed:'),
  },
  components: {
    GlBadge,
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
        <template v-if="!humanizedActions.length">{{ $options.i18n.noActionMessage }}</template>
        <div v-for="{ message, tags } in humanizedActions" :key="message" class="gl-mb-3">
          <gl-sprintf :message="message">
            <template #scanner="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
          <div v-if="tags" class="gl-mt-2 gl-display-flex gl-gap-2 gl-flex-wrap">
            <gl-badge v-for="tag in tags" :key="tag" variant="info" size="sm">
              {{ tag }}
            </gl-badge>
          </div>
        </div>
        <div class="gl-mb-3">{{ $options.i18n.ruleMessage }}</div>
        <ul>
          <li v-for="(rule, idx) in humanizedRules" :key="idx">
            {{ rule }}
          </li>
        </ul>
      </policy-info-row>
    </template>
  </policy-drawer-layout>
</template>
