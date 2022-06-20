<script>
import { GlPopover, GlIcon, GlTooltip } from '@gitlab/ui';
import { s__, n__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CodequalityIssueBody from '~/reports/codequality_report/components/codequality_issue_body.vue';
import { SEVERITY_CLASSES, SEVERITY_ICONS } from '~/reports/codequality_report/constants';

export default {
  components: {
    GlIcon,
    GlPopover,
    CodequalityIssueBody,
    GlTooltip,
  },
  i18n: {
    popoverTitle: s__('CodeQuality|New code quality degradations on this line'),
  },
  mixins: [glFeatureFlagsMixin()],
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
    tooltipText() {
      return n__('1 Code quality finding', '%d Code quality findings', this.codequality.length);
    },
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
  <div
    v-if="glFeatures.refactorCodeQualityInlineFindings"
    @click="$emit('showCodeQualityFindings')"
  >
    <span ref="codeQualityIcon">
      <gl-icon
        :id="`codequality-${filePath}:${line}`"
        :size="12"
        :name="severityIcon"
        :class="severityClass"
        class="gl-hover-cursor-pointer codequality-severity-icon"
      />
    </span>
    <gl-tooltip data-testid="codeQualityTooltip" :target="() => $refs.codeQualityIcon">
      {{ tooltipText }}
    </gl-tooltip>
  </div>
  <div v-else>
    <gl-icon
      :id="`codequality-${filePath}:${line}`"
      :size="12"
      :name="severityIcon"
      :class="severityClass"
      class="gl-hover-cursor-pointer codequality-severity-icon"
    />
    <gl-popover
      triggers="hover focus"
      placement="topright"
      :css-classes="['gl-max-w-max-content', 'gl-w-half']"
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
