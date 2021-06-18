<script>
import { GlPopover, GlIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import CodequalityIssueBody from '~/reports/codequality_report/components/codequality_issue_body.vue';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/reports/codequality_report/constants';

export default {
  components: {
    GlIcon,
    GlPopover,
    CodequalityIssueBody,
  },
  modalCloseButton: {
    text: __('Close'),
    attributes: [{ variant: 'info' }],
  },
  i18n: {
    popoverTitle: s__('CodeQuality|New code quality degradations on this line'),
  },
  props: {
    filePath: {
      type: String,
      required: true,
    },
    codequality: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    severity() {
      return this.codequality[0].severity;
    },
    severityClass() {
      return SEVERITY_CLASSES[this.severity] || SEVERITY_CLASSES.unknown;
    },
    severityIcon() {
      return SEVERITY_ICONS[this.severity] || SEVERITY_ICONS.unknown;
    },
    line() {
      return this.codequality[0].line;
    },
    degradations() {
      return this.codequality.map((degradation) => {
        return {
          name: degradation.description,
          severity: degradation.severity,
        };
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-icon
      :id="`codequality-${filePath}:${line}`"
      :size="12"
      :name="severityIcon"
      :class="severityClass"
      class="gl-hover-cursor-pointer codequality-severity-icon"
    />
    <gl-popover
      triggers="click blur"
      placement="topright"
      :css-classes="['gl-max-w-none', 'gl-w-half']"
      :target="`codequality-${filePath}:${line}`"
      :title="$options.i18n.popoverTitle"
    >
      <codequality-issue-body
        v-for="(degradation, index) in degradations"
        :key="index"
        :issue="degradation"
      />
    </gl-popover>
  </div>
</template>
