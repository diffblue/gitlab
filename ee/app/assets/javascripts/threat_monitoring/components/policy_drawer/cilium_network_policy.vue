<script>
import { GlIntersperse } from '@gitlab/ui';
import { n__, s__ } from '~/locale';
import { removeUnnecessaryDashes } from '../../utils';
import { fromYaml, humanizeNetworkPolicy } from '../policy_editor/network_policy/lib';
import PolicyPreview from '../policy_editor/policy_preview.vue';
import BasePolicy from './base_policy.vue';
import PolicyInfoRow from './policy_info_row.vue';

export default {
  i18n: {
    description: s__('SecurityOrchestration|Description'),
    network: s__('NetworkPolicies|Network'),
    status: s__('SecurityOrchestration|Status'),
  },
  components: {
    GlIntersperse,
    BasePolicy,
    PolicyPreview,
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
  },
};
</script>

<template>
  <base-policy :policy="policy">
    <template #type>{{ $options.i18n.network }}</template>

    <template #default="{ statusLabel }">
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

      <policy-preview
        class="gl-mt-4"
        :initial-tab="initialTab"
        :policy-yaml="policyYaml"
        :policy-description="humanizedPolicy"
      />
    </template>
  </base-policy>
</template>
