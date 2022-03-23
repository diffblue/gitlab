<script>
import { GlPath } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getParameterByName, removeParams, visitUrl } from '~/lib/utils/url_utility';
import { POLICY_TYPE_COMPONENT_OPTIONS } from '../constants';
import PolicySelection from './policy_selection.vue';
import PolicyEditor from './policy_editor_v2.vue';

export default {
  components: {
    GlPath,
    PolicyEditor,
    PolicySelection,
  },
  // TODO: move this `inject` instead of `props`. We're using it in multiple levels.
  props: {
    assignedPolicyProject: {
      type: Object,
      required: true,
    },
    existingPolicy: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      selectedPolicy: this.policyFromUrl(),
    };
  },
  computed: {
    glPathItems() {
      const hasPolicy = Boolean(this.selectedPolicy);

      return [
        {
          title: this.$options.i18n.choosePolicyType,
          selected: !hasPolicy,
        },
        {
          title: this.$options.i18n.policyDetails,
          selected: hasPolicy,
          disabled: !hasPolicy,
        },
      ];
    },
    title() {
      if (this.existingPolicy) {
        return this.$options.i18n.editTitles[this.selectedPolicy.value];
      }

      if (this.selectedPolicy) {
        return this.$options.i18n.titles[this.selectedPolicy.value];
      }

      return this.$options.i18n.titles.default;
    },
  },
  methods: {
    handlePathSelection({ title }) {
      if (title === this.$options.i18n.choosePolicyType) {
        visitUrl(removeParams(['type'], window.location.href));
      }
    },
    policyFromUrl() {
      const policyType = getParameterByName('type');

      return Object.values(POLICY_TYPE_COMPONENT_OPTIONS).find(
        ({ urlParameter }) => urlParameter === policyType,
      );
    },
  },
  i18n: {
    titles: {
      [POLICY_TYPE_COMPONENT_OPTIONS.container.value]: s__(
        'SecurityOrchestration|New network policy',
      ),
      [POLICY_TYPE_COMPONENT_OPTIONS.scanResult.value]: s__(
        'SecurityOrchestration|New scan result policy',
      ),
      [POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value]: s__(
        'SecurityOrchestration|New scan exection policy',
      ),
      default: s__('SecurityOrchestration|New policy'),
    },
    editTitles: {
      [POLICY_TYPE_COMPONENT_OPTIONS.container.value]: s__(
        'SecurityOrchestration|Edit network policy',
      ),
      [POLICY_TYPE_COMPONENT_OPTIONS.scanResult.value]: s__(
        'SecurityOrchestration|Edit scan result policy',
      ),
      [POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value]: s__(
        'SecurityOrchestration|Edit scan exection policy',
      ),
      default: s__('SecurityOrchestration|New policy'),
    },
    choosePolicyType: s__('SecurityOrchestration|Step 1: Choose a policy type'),
    policyDetails: s__('SecurityOrchestration|Step 2: Policy details'),
  },
};
</script>
<template>
  <div>
    <header class="gl-pb-5 gl-border-b-none">
      <h3>{{ title }}</h3>
      <gl-path v-if="!existingPolicy" :items="glPathItems" @selected="handlePathSelection" />
    </header>
    <policy-selection v-if="!selectedPolicy" />
    <policy-editor
      v-else
      :assigned-policy-project="assignedPolicyProject"
      :existing-policy="existingPolicy"
      :selected-policy-type="selectedPolicy.value"
    />
  </div>
</template>
