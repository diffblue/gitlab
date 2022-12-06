<script>
import { GlPath } from '@gitlab/ui';
import { s__ } from '~/locale';
import { getParameterByName, removeParams, visitUrl } from '~/lib/utils/url_utility';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { POLICY_TYPE_COMPONENT_OPTIONS } from '../constants';
import PolicySelection from './policy_selection.vue';
import PolicyEditor from './policy_editor.vue';

export default {
  components: {
    GlPath,
    PolicyEditor,
    PolicySelection,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    namespaceType: { default: '' },
    existingPolicy: { default: null },
  },
  data() {
    return {
      selectedPolicy: this.policyFromUrl(),
    };
  },
  computed: {
    enableWizard() {
      return !this.existingPolicy;
    },
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
      [POLICY_TYPE_COMPONENT_OPTIONS.scanResult.value]: s__(
        'SecurityOrchestration|New scan result policy',
      ),
      [POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value]: s__(
        'SecurityOrchestration|New scan execution policy',
      ),
      default: s__('SecurityOrchestration|New policy'),
    },
    editTitles: {
      [POLICY_TYPE_COMPONENT_OPTIONS.scanResult.value]: s__(
        'SecurityOrchestration|Edit scan result policy',
      ),
      [POLICY_TYPE_COMPONENT_OPTIONS.scanExecution.value]: s__(
        'SecurityOrchestration|Edit scan execution policy',
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
    <header class="gl-border-b-none gl-mb-4">
      <h3>{{ title }}</h3>
      <gl-path v-if="enableWizard" :items="glPathItems" @selected="handlePathSelection" />
    </header>
    <policy-selection v-if="!selectedPolicy" />
    <policy-editor v-else :selected-policy-type="selectedPolicy.value" />
  </div>
</template>
