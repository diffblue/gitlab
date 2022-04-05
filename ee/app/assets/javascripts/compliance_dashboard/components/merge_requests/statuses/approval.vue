<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

const APPROVAL_WARNING_ICON = 'success-with-warnings';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiIcon,
    GlLink,
  },
  props: {
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    tooltip() {
      return this.$options.tooltips[this.status];
    },
    icon() {
      return `status_${this.status}`;
    },
    group() {
      if (this.status === 'warning') {
        return APPROVAL_WARNING_ICON;
      }

      return this.status;
    },
  },
  tooltips: {
    success: s__('ApprovalStatusTooltip|Adheres to separation of duties'),
    warning: s__('ApprovalStatusTooltip|At least one rule does not adhere to separation of duties'),
    failed: s__('ApprovalStatusTooltip|Fails to adhere to separation of duties'),
  },
  docLink: helpPagePath('user/compliance/compliance_report/index', {
    anchor: 'separation-of-duties',
  }),
};
</script>

<template>
  <gl-link :href="$options.docLink">
    <ci-icon v-gl-tooltip.left="tooltip" class="gl-display-flex" :status="{ icon, group }" />
  </gl-link>
</template>
