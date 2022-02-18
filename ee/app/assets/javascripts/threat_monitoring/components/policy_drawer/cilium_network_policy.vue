<script>
import { GlIntersperse } from '@gitlab/ui';
import { n__, s__ } from '~/locale';
import { removeUnnecessaryDashes } from '../../utils';
import { fromYaml, humanizeNetworkPolicy } from '../policy_editor/network_policy/lib';
import PolicyPreviewHuman from '../policy_editor/policy_preview_human.vue';
import PolicyInfoRow from './policy_info_row.vue';
import { ENABLED_LABEL, NOT_ENABLED_LABEL } from './constants';

export default {
  i18n: {
    description: s__('SecurityOrchestration|Description'),
    network: s__('NetworkPolicies|Network'),
    status: s__('SecurityOrchestration|Status'),
    summary: s__('SecurityOrchestration|Summary'),
  },
  components: {
    GlIntersperse,
    PolicyPreviewHuman,
    PolicyInfoRow,
  },
  props: {
    policy: {
      type: Object,
      required: true,
    },
  },
  computed: {
    parsedYaml() {
      try {
        const parsedYaml = fromYaml(this.policy.yaml);
        return parsedYaml.error ? null : parsedYaml;
      } catch (e) {
        return null;
      }
    },
    initialTab() {
      return this.parsedYaml ? 0 : 1;
    },
    humanizedPolicy() {
      return this.parsedYaml ? humanizeNetworkPolicy(this.parsedYaml) : this.parsedYaml;
    },
    policyYaml() {
      return removeUnnecessaryDashes(this.policy.yaml);
    },
    environments() {
      return this.policy.environments?.nodes ?? [];
    },
    environmentLabel() {
      return n__('Environment', 'Environments', this.environments.length);
    },
    statusLabel() {
      return this.policy?.enabled ? ENABLED_LABEL : NOT_ENABLED_LABEL;
    },
  },
};
</script>

<template>
  <div>
    <h5 class="gl-mt-3">{{ __('Type') }}</h5>
    <p data-testid="policy-type">
      {{ $options.i18n.network }}
    </p>

    <policy-info-row :label="$options.i18n.summary">
      <policy-preview-human :policy-description="humanizedPolicy" />
    </policy-info-row>

    <div v-if="parsedYaml">
      <policy-info-row
        v-if="parsedYaml.description"
        data-testid="description"
        :label="$options.i18n.description"
      >
        {{ parsedYaml.description }}
      </policy-info-row>

      <policy-info-row :label="$options.i18n.status">{{ statusLabel }}</policy-info-row>

      <policy-info-row
        v-if="environments.length"
        data-testid="environments"
        :label="environmentLabel"
      >
        <gl-intersperse>
          <span v-for="environment in environments" :key="environment.name">
            {{ environment.name }}
          </span>
        </gl-intersperse>
      </policy-info-row>
    </div>
  </div>
</template>
