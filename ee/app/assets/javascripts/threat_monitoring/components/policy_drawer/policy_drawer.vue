<script>
import { GlButton, GlDrawer } from '@gitlab/ui';
import { getContentWrapperHeight, getPolicyKind } from '../../utils';
import { POLICIES_LIST_CONTAINER_CLASS, POLICY_KINDS } from '../constants';
import CiliumNetworkPolicy from './cilium_network_policy.vue';
import ScanExecutionPolicy from './scan_execution_policy.vue';

const policyComponent = {
  [POLICY_KINDS.ciliumNetwork]: CiliumNetworkPolicy,
  [POLICY_KINDS.scanExecution]: ScanExecutionPolicy,
};

export default {
  components: {
    GlButton,
    GlDrawer,
    PolicyYamlEditor: () =>
      import(/* webpackChunkName: 'policy_yaml_editor' */ '../policy_yaml_editor.vue'),
    CiliumNetworkPolicy,
    ScanExecutionPolicy,
  },
  props: {
    containerClass: {
      type: String,
      required: false,
      default: POLICIES_LIST_CONTAINER_CLASS,
    },
    policy: {
      type: Object,
      required: false,
      default: null,
    },
    editPolicyPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    policyKind() {
      return getPolicyKind(this.policy?.yaml);
    },
    policyComponent() {
      return policyComponent[this.policyKind] || null;
    },
  },
  methods: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight(this.containerClass);
    },
  },
  // We set the drawer's z-index to 252 to clear flash messages that might be displayed in the page
  // and that have a z-index of 251.
  DRAWER_Z_INDEX: 252,
};
</script>

<template>
  <gl-drawer
    :z-index="$options.DRAWER_Z_INDEX"
    :header-height="getDrawerHeaderHeight()"
    v-bind="$attrs"
    v-on="$listeners"
  >
    <template v-if="policy" #title>
      <h3 class="gl-my-0">{{ policy.name }}</h3>
    </template>
    <template v-if="policy" #header>
      <gl-button
        class="gl-mt-5"
        data-testid="edit-button"
        category="primary"
        variant="info"
        :href="editPolicyPath"
        >{{ s__('NetworkPolicies|Edit policy') }}</gl-button
      >
    </template>
    <div v-if="policy">
      <component :is="policyComponent" v-if="policyComponent" :policy="policy" />
      <div v-else>
        <h5>{{ s__('NetworkPolicies|Policy definition') }}</h5>
        <p>
          {{ s__("NetworkPolicies|Define this policy's location, conditions and actions.") }}
        </p>
        <div class="gl-p-3 gl-bg-gray-50">
          <policy-yaml-editor
            :value="policy.yaml"
            data-testid="policy-yaml-editor"
            class="network-policy-editor"
          />
        </div>
      </div>
    </div>
  </gl-drawer>
</template>
