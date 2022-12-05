<script>
import { GlPopover, GlIcon, GlTooltip } from '@gitlab/ui';
import { s__, n__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CodequalityIssueBody from '~/ci/reports/codequality_report/components/codequality_issue_body.vue';
import { SEVERITIES } from '~/ci/reports/codequality_report/constants';

const codequalityCountThreshold = 3;

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
  data() {
    return {
      isHoveringFirstIcon: false,
    };
  },
  computed: {
    tooltipTextCollapsed() {
      return n__('1 Code quality finding', '%d Code quality findings', this.codequality.length);
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
    moreCount() {
      return this.codequality.length > codequalityCountThreshold
        ? this.codequality.length - codequalityCountThreshold
        : 0;
    },
    severity() {
      return this.codequality.reduce((acc, elem) => {
        return { ...acc, [elem.severity]: SEVERITIES[elem.severity] || SEVERITIES.unknown };
      }, {});
    },
    firstCodequalityItem() {
      return this.codequality[0];
    },
    codeQualitySubItems() {
      return this.codequality.slice(1, 3);
    },
  },
};
</script>

<template>
  <div
    v-if="glFeatures.refactorCodeQualityInlineFindings"
    class="gl-z-index-1 gl-relative"
    @click="$emit('showCodeQualityFindings')"
  >
    <div
      v-if="!codeQualityExpanded"
      class="codequality-severity-icon-container gl-display-inline-flex"
    >
      <span ref="codeQualityIcon" class="gl-z-index-200">
        <gl-icon
          :id="`codequality-${firstCodequalityItem.filePath}:${firstCodequalityItem.line}`"
          ref="firstCodeQualityIcon"
          :key="firstCodequalityItem.description"
          :size="16"
          :name="severity[firstCodequalityItem.severity].name"
          :class="severity[firstCodequalityItem.severity].class"
          class="gl-hover-cursor-pointer gl-relative gl-top-1 codequality-severity-icon gl-vertical-align-baseline!"
          @mouseenter="isHoveringFirstIcon = true"
          @mouseleave="isHoveringFirstIcon = false"
        />
      </span>
      <gl-icon
        v-for="item in codeQualitySubItems"
        :key="item.description"
        :size="16"
        :name="severity[item.severity].name"
        :class="[isHoveringFirstIcon ? 'first-icon-hovered' : '', severity[item.severity].class]"
        class="gl-hover-cursor-pointer gl-relative gl-top-1 codequality-severity-icon gl-absolute gl-left-0 gl-opacity-0"
      />
      <div
        v-if="moreCount"
        :class="[
          isHoveringFirstIcon ? 'first-icon-hovered' : '',
          'more-count gl-px-2 gl-w-auto gl-absolute gl-left-0 gl-opacity-0 gl-relative gl-top-1',
        ]"
        data-testid="codeQualityMoreCount"
      >
        <p class="gl-mb-0 gl-display-block gl-w-3 more-count-copy">
          {{ moreCount }}
        </p>
      </div>
    </div>
    <button v-else class="diff-codequality-collapse gl-mx-n2">
      <gl-icon :size="12" name="collapse" />
    </button>
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
      :name="severity[firstCodequalityItem.severity].name"
      :class="severity[firstCodequalityItem.severity].class"
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
