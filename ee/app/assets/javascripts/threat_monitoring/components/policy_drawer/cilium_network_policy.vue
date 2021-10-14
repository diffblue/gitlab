<script>
import { GlIntersperse } from '@gitlab/ui';
import { removeUnnecessaryDashes } from '../../utils';
import { fromYaml, humanizeNetworkPolicy } from '../policy_editor/network_policy/lib';
import PolicyPreview from '../policy_editor/policy_preview.vue';
import BasePolicy from './base_policy.vue';
import PolicyInfoRow from './policy_info_row.vue';

export default {
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
  },
};
</script>

<template>
  <base-policy :policy="policy">
    <template #type>{{ s__('NetworkPolicies|Network') }}</template>

    <template #default="{ statusLabel }">
      <div v-if="parsedYaml">
        <policy-info-row
          v-if="parsedYaml.description"
          data-testid="description"
          :label="__('Description')"
          >{{ parsedYaml.description }}</policy-info-row
        >

        <policy-info-row :label="__('Status')">{{ statusLabel }}</policy-info-row>

        <policy-info-row
          v-if="environments.length"
          data-testid="environments"
          :label="s__('SecurityPolicies|Environment(s)')"
        >
          <gl-intersperse>
            <span v-for="environment in environments" :key="environment.name">{{
              environment.name
            }}</span>
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
