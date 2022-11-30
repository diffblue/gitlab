<script>
import { GlIcon, GlButton } from '@gitlab/ui';
import { i18nPolicyText } from '../../constants';
import EscalationPolicyHelpState from './escalation_policy_help_state.vue';
import EscalationPolicyCollapsedState from './escalation_policy_collapsed_state.vue';

export default {
  i18n: i18nPolicyText,
  components: {
    GlIcon,
    GlButton,
    EscalationPolicyCollapsedState,
    EscalationPolicyHelpState,
  },
  data() {
    return {
      showHelp: false,
    };
  },
  methods: {
    toggleHelpState() {
      this.showHelp = !this.showHelp;
    },
  },
};
</script>

<template>
  <div data-testid="escalation-policy-edit">
    <div class="hide-collapsed sidebar-help-wrap">
      <div
        class="gl-line-height-2 gl-text-gray-900 gl-display-flex gl-align-items-center gl-mb-2 gl-font-weight-bold"
      >
        <span>{{ $options.i18n.title }}</span>
        <gl-button
          :data-testid="showHelp ? 'close-help-button' : 'help-button'"
          category="tertiary"
          size="small"
          variant="link"
          class="gl-ml-auto"
          @click="toggleHelpState"
        >
          <gl-icon :name="showHelp ? 'close' : 'question-o'" class="gl-text-gray-900!" />
        </gl-button>
      </div>

      <div data-testid="select-escalation-policy" class="hide-collapsed gl-line-height-14">
        <span class="gl-text-gray-500">
          {{ $options.i18n.none }}
        </span>
      </div>

      <escalation-policy-help-state v-if="showHelp" />
    </div>

    <escalation-policy-collapsed-state />
  </div>
</template>
