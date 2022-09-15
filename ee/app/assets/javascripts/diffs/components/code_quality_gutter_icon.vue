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
    codeQualityExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    tooltipTextCollapsed() {
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
        v-if="!$props.codeQualityExpanded"
        :id="`codequality-${filePath}:${line}`"
        :size="12"
        :name="severityIcon"
        :class="severityClass"
        class="gl-hover-cursor-pointer codequality-severity-icon"
      />
      <button v-else class="diff-codequality-collapse gl-mx-n2">
        <gl-icon :size="12" name="collapse" />
      </button>
    </span>
    <!-- Only show tooltip when indicator is not expanded
      a) to stay consistent with other collapsed icon on the same page
      b) because the tooltip would be misaligned hence the negative margin
     -->
    <gl-tooltip
      v-if="!$props.codeQualityExpanded"
      data-testid="codeQualityTooltip"
      :target="() => $refs.codeQualityIcon"
    >
      {{ tooltipTextCollapsed }}
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
