<script>
import { GlTabs, GlTab } from '@gitlab/ui';
import { PARSING_ERROR_MESSAGE } from './constants';
import PolicyPreviewHuman from './policy_preview_human.vue';

export default {
  i18n: {
    PARSING_ERROR_MESSAGE,
  },
  components: {
    GlTabs,
    GlTab,
    PolicyPreviewHuman,
  },
  props: {
    policyYaml: {
      type: String,
      required: true,
    },
    policyDescription: {
      type: String,
      required: false,
      default: '',
    },
    initialTab: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return { selectedTab: this.initialTab };
  },
};
</script>

<template>
  <gl-tabs v-model="selectedTab" content-class="gl-pt-0">
    <gl-tab :title="s__('NetworkPolicies|Rule')">
      <policy-preview-human
        :class="{
          'gl-border-t-none! gl-rounded-top-left-none gl-rounded-top-right-none': Boolean(
            policyDescription,
          ),
        }"
        :policy-description="policyDescription"
      />
    </gl-tab>
    <gl-tab :title="s__('NetworkPolicies|.yaml')">
      <pre class="gl-bg-white gl-rounded-top-left-none gl-rounded-top-right-none gl-border-t-none"
        >{{ policyYaml }}
      </pre>
    </gl-tab>
  </gl-tabs>
</template>
