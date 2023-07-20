<script>
import EscalationStatus from '~/sidebar/components/incidents/escalation_status.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { i18nStatusHeaderText, STATUS_SUBTEXTS } from '../../constants';

export default {
  i18n: i18nStatusHeaderText,

  components: {
    EscalationStatus,
  },
  mixins: [glFeatureFlagMixin()],
  computed: {
    headerText() {
      return this.escalationPoliciesEnabled ? this.$options.i18n : '';
    },
    statusSubtexts() {
      return this.escalationPoliciesEnabled ? STATUS_SUBTEXTS : {};
    },

    escalationPoliciesEnabled() {
      return this.glFeatures.escalationPolicies;
    },
  },
  methods: {
    show() {
      this.$refs.escalationStatus.show();
    },
    // Pass through to wrapped component
    hide() {
      this.$refs.escalationStatus.hide();
    },
  },
};
</script>

<template>
  <escalation-status
    ref="escalationStatus"
    :header-text="headerText"
    :status-subtexts="statusSubtexts"
    v-bind="$attrs"
    v-on="$listeners"
  />
</template>
