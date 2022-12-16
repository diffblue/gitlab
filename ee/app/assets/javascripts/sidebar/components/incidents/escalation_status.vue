<script>
import { GlDropdownDivider, GlDropdownSectionHeader, GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import EscalationStatus from '~/sidebar/components/incidents/escalation_status.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { helpPagePath } from '~/helpers/help_page_helper';
import { i18nStatusText } from '../../constants';

export default {
  i18n: i18nStatusText,
  docsPath: helpPagePath('operations/incident_management/manage_incidents.html', {
    anchor: 'change-status',
  }),
  components: {
    EscalationStatus,
    GlDropdownDivider,
    GlDropdownSectionHeader,
    GlIcon,
    GlPopover,
    GlLink,
  },
  mixins: [glFeatureFlagMixin()],
  data() {
    return { isHelpVisible: false };
  },
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
    showPopover() {
      this.isHelpVisible = true;
    },
    hidePopover() {
      this.isHelpVisible = false;
    },
  },
};
</script>

<template>
  <escalation-status
    ref="escalationStatus"
    v-bind="$attrs"
    :prevent-dropdown-close="isHelpVisible"
    v-on="$listeners"
  >
    <template v-if="showHeader" #header>
      <gl-dropdown-section-header id="escalation-status-dropdown" class="gl-mt-n2">
        <div class="gl-text-center">
          {{ $options.i18n.dropdownHeader }}
          <gl-icon id="escalation-status-help" class="gl-ml-2 gl-text-blue-600" name="question-o" />
          <gl-popover
            ref="popover"
            :title="$options.i18n.dropdownHeader"
            placement="left"
            target="escalation-status-help"
            boundary="viewport"
            @show="showPopover"
            @hide="hidePopover"
          >
            <p @click.stop.prevent>{{ $options.i18n.dropdownInfo }}</p>
            <gl-link
              ref="link"
              :aria-label="$options.i18n.learnMoreFull"
              class="gl-font-sm"
              :href="$options.docsPath"
              target="_blank"
            >
              {{ $options.i18n.learnMoreShort }}
            </gl-link>
          </gl-popover>
        </div>
      </gl-dropdown-section-header>
      <gl-dropdown-divider />
    </template>
  </escalation-status>
</template>
