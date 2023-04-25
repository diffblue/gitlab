<script>
import { GlLink, GlPopover, GlIcon } from '@gitlab/ui';
import { COVERAGE_CHECK_NAME, APPROVAL_RULE_CONFIGS } from 'ee/approvals/constants';

export default {
  components: {
    GlLink,
    GlPopover,
    GlIcon,
  },
  inject: {
    coverageCheckHelpPagePath: {
      default: '',
    },
  },
  props: {
    name: {
      type: String,
      required: true,
    },
  },
  computed: {
    rulesWithTooltips() {
      return {
        [COVERAGE_CHECK_NAME]: {
          description: APPROVAL_RULE_CONFIGS[COVERAGE_CHECK_NAME].popoverText,
          linkPath: this.coverageCheckHelpPagePath,
        },
      };
    },
    description() {
      return this.rulesWithTooltips[this.name]?.description;
    },
    linkPath() {
      return this.rulesWithTooltips[this.name]?.linkPath;
    },
  },
  methods: {
    popoverTarget() {
      return this.$refs.helpIcon?.$el;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <span class="gl-mt-n2">{{ name }}</span>
    <span v-if="description" class="gl-ml-3">
      <gl-icon
        ref="helpIcon"
        name="question-o"
        :aria-label="__('Help')"
        :size="14"
        class="author-link gl-cursor-help"
      />
      <gl-popover :target="popoverTarget" placement="top">
        <template #title>{{ __('Who can approve?') }}</template>
        <p>{{ description }}</p>
        <gl-link v-if="linkPath" :href="linkPath" class="gl-font-sm" target="_blank">{{
          __('More information')
        }}</gl-link>
      </gl-popover>
    </span>
  </div>
</template>
