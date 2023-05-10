<script>
import {
  GlButton,
  GlDrawer,
  GlLink,
  GlSprintf,
  GlTabs,
  GlTab,
  GlTooltip,
  GlTruncate,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { removeUnnecessaryDashes } from '../../utils';
import { POLICIES_LIST_CONTAINER_CLASS, POLICY_TYPE_COMPONENT_OPTIONS } from '../constants';
import { getPolicyListUrl, isPolicyInherited } from '../utils';
import ScanExecutionPolicy from './scan_execution_policy.vue';
import ScanResultPolicy from './scan_result_policy.vue';

const policyComponent = {
  [POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value]: ScanExecutionPolicy,
  [POLICY_TYPE_COMPONENT_OPTIONS.scanResult.value]: ScanResultPolicy,
};

export default {
  components: {
    GlButton,
    GlDrawer,
    GlLink,
    GlSprintf,
    GlTab,
    GlTabs,
    GlTooltip,
    GlTruncate,
    PolicyYamlEditor: () =>
      import(/* webpackChunkName: 'policy_yaml_editor' */ '../policy_yaml_editor.vue'),
    ScanExecutionPolicy,
    ScanResultPolicy,
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
    policyType: {
      type: String,
      required: false,
      default: '',
    },
    editPolicyPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isPolicyInherited() {
      return isPolicyInherited(this.policy.source);
    },
    policyComponent() {
      return policyComponent[this.policyType] || null;
    },
    policyYaml() {
      return removeUnnecessaryDashes(this.policy.yaml);
    },
    sourcePolicyListUrl() {
      return getPolicyListUrl({ namespacePath: this.policy.source.namespace.fullPath });
    },
  },
  methods: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight(this.containerClass);
    },
  },
  DRAWER_Z_INDEX,
  i18n: {
    editButtonTooltipMessage: s__(
      'SecurityOrchestration|This policy is inherited from the %{linkStart}namespace%{linkEnd} and must be edited there',
    ),
    tabDetails: s__('SecurityOrchestration|Details'),
    tabYaml: s__('SecurityOrchestration|YAML'),
  },
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
      <gl-truncate
        class="gl-font-size-h2 gl-font-weight-bold gl-line-height-24 gl-max-w-34"
        :text="policy.name"
        with-tooltip
      />
    </template>
    <template v-if="policy" #header>
      <span ref="editButton" class="gl-display-inline-block">
        <gl-button
          class="gl-mt-5"
          data-testid="edit-button"
          category="primary"
          variant="confirm"
          :href="editPolicyPath"
          :disabled="isPolicyInherited"
          >{{ s__('SecurityOrchestration|Edit policy') }}</gl-button
        >
      </span>
      <gl-tooltip
        v-if="isPolicyInherited"
        :target="() => $refs.editButton"
        data-testid="edit-button-tooltip"
        placement="bottom"
      >
        <gl-sprintf :message="$options.i18n.editButtonTooltipMessage">
          <template #link>
            <gl-link :href="sourcePolicyListUrl">
              {{ policy.source.namespace.name }}
            </gl-link>
          </template>
        </gl-sprintf>
      </gl-tooltip>
    </template>
    <gl-tabs v-if="policy" class="gl-p-0!" justified content-class="gl-py-0" lazy>
      <gl-tab :title="$options.i18n.tabDetails" class="gl-mt-5 gl-ml-6 gl-mr-3">
        <component :is="policyComponent" v-if="policyComponent" :policy="policy" />
        <div v-else>
          <h5>{{ s__('SecurityOrchestration|Policy definition') }}</h5>
          <p>
            {{
              s__("SecurityOrchestration|Define this policy's location, conditions and actions.")
            }}
          </p>
          <policy-yaml-editor
            :value="policyYaml"
            data-testid="policy-yaml-editor-default-component"
          />
        </div>
      </gl-tab>
      <gl-tab v-if="policyComponent" :title="$options.i18n.tabYaml">
        <policy-yaml-editor
          class="gl-h-100vh"
          :value="policyYaml"
          data-testid="policy-yaml-editor-tab-content"
        />
      </gl-tab>
    </gl-tabs>
  </gl-drawer>
</template>
