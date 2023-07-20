<script>
import { GlIcon, GlTooltip } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import { n__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getSeverity } from '~/ci/reports/utils';
import { SAST_SCALE_KEY, CODE_QUALITY_SCALE_KEY } from '~/ci/reports/constants';

const codequalityCountThreshold = 3;

export default {
  components: {
    GlIcon,
    GlTooltip,
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
    sast: {
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
    combinedFindings() {
      // add scale info
      this.codequality.map((e) => {
        const scaledCodeQuality = e;
        scaledCodeQuality.scale = CODE_QUALITY_SCALE_KEY;
        return scaledCodeQuality;
      });
      this.sast.map((e) => {
        const scaledSast = e;
        scaledSast.scale = SAST_SCALE_KEY;
        return scaledSast;
      });

      // cloneDeep to not mutate props
      return this.codequality.concat(cloneDeep(this.sast));
    },
    codeQualityTooltipTextCollapsed() {
      return n__('1 Code Quality finding', '%d Code Quality findings', this.codequality.length);
    },
    sastTooltipTextCollapsed() {
      return n__('1 Security finding', '%d Security findings', this.sast.length);
    },
    showMoreCount() {
      return this.moreCount && this.isHoveringFirstIcon;
    },
    line() {
      return this.combinedFindings[0].line;
    },
    moreCount() {
      return this.combinedFindings.length > codequalityCountThreshold
        ? this.combinedFindings.length - codequalityCountThreshold
        : 0;
    },
    findingsWithSeverity() {
      return getSeverity(this.combinedFindings);
    },
    firstCodequalityItem() {
      return { ...this.combinedFindings[0], filePath: this.filePath };
    },
    codeQualitySubItems() {
      return this.findingsWithSeverity.slice(1, codequalityCountThreshold);
    },
  },
};
</script>

<template>
  <div
    v-if="findingsWithSeverity.length"
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
          :name="findingsWithSeverity[0].name"
          :class="findingsWithSeverity[0].class"
          class="gl-hover-cursor-pointer gl-relative gl-top-1 inline-findings-severity-icon gl-vertical-align-baseline!"
          @mouseenter="isHoveringFirstIcon = true"
          @mouseleave="isHoveringFirstIcon = false"
        />
      </span>
      <span class="code-quality-transition-container gl-display-inline-flex">
        <transition-group name="icons">
          <!--
            The TransitionGroup Component will only apply its classes when first-level children are added/removed to the DOM.
            So to make TransitionGroup work there is no other way to use v-if-with-v-for in this case.
          -->
          <!-- eslint-disable vue/no-use-v-if-with-v-for -->
          <gl-icon
            v-for="(item, index) in codeQualitySubItems"
            v-if="isHoveringFirstIcon"
            :key="item.description"
            :name="codeQualitySubItems[index].name"
            :class="codeQualitySubItems[index].class"
            class="gl-hover-cursor-pointer gl-relative gl-top-1 inline-findings-severity-icon gl-absolute gl-left-0"
          />
          <!-- eslint-enable -->
        </transition-group>
        <transition name="more-count">
          <div
            v-if="showMoreCount"
            class="more-count gl-px-2 gl-w-auto gl-absolute gl-left-0 gl-relative gl-top-1"
            data-testid="codeQualityMoreCount"
          >
            <p class="gl-mb-0 gl-display-block gl-w-3 more-count-copy">{{ moreCount }}</p>
          </div>
        </transition>
      </span>
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
      <span v-if="codequality.length" class="gl-display-block">{{
        codeQualityTooltipTextCollapsed
      }}</span>
      <span v-if="sast.length" class="gl-display-block">{{ sastTooltipTextCollapsed }}</span>
    </gl-tooltip>
  </div>
</template>
