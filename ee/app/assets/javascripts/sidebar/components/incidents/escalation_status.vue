<script>
import { GlDropdownDivider, GlDropdownSectionHeader, GlIcon, GlPopover } from '@gitlab/ui';
import EscalationStatus from '~/sidebar/components/incidents/escalation_status.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { i18nStatusText } from './constants';

export default {
  i18n: i18nStatusText,
  components: {
    EscalationStatus,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlIcon,
    GlPopover,
  },
  mixins: [glFeatureFlagMixin()],
  computed: {
    showHeader() {
      return this.glFeatures.escalationPolicies;
    },
  },
  methods: {
    // Pass through to wrapped component
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
  <escalation-status ref="escalationStatus" v-bind="$attrs" v-on="$listeners">
    <template v-if="showHeader" #header>
      <gl-dropdown-section-header class="gl-mt-n2">
        <div class="gl-text-center">
          {{ $options.i18n.dropdownHeader }}
          <gl-icon id="escalation-status-help" class="gl-ml-2 gl-text-blue-600" name="question-o" />
          <gl-popover
            :content="$options.i18n.dropdownInfo"
            :title="$options.i18n.dropdownHeader"
            boundary="viewport"
            placement="left"
            target="escalation-status-help"
          />
        </div>
      </gl-dropdown-section-header>
      <gl-dropdown-divider />
    </template>
  </escalation-status>
</template>
