<script>
import { GlIcon, GlTooltip } from '@gitlab/ui';
import { n__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getSeverity } from '~/ci/reports/utils';
import { CODE_QUALITY_SCALE_KEY } from '~/ci/reports/constants';

const inlineFindingsCountThreshold = 3;

export default {
  components: {
    GlIcon,
    GlTooltip,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    inlineFindingsExpanded: {
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
    combinedFindings() {
      // add scale info
      this.codequality.map((e) => {
        const scaledCodeQuality = e;
        scaledCodeQuality.scale = CODE_QUALITY_SCALE_KEY;
        return scaledCodeQuality;
      });

      // cloneDeep to not mutate props
      return this.codequality;
    },
    codeQualityTooltipTextCollapsed() {
      return n__('1 Code Quality finding', '%d Code Quality findings', this.codequality.length);
    },
    showMoreCount() {
      return this.moreCount && this.isHoveringFirstIcon;
    },
    line() {
      return this.combinedFindings[0].line;
    },
    moreCount() {
      return this.combinedFindings.length > inlineFindingsCountThreshold
        ? this.combinedFindings.length - inlineFindingsCountThreshold
        : 0;
    },
    findingsWithSeverity() {
      return getSeverity(this.combinedFindings);
    },
    firstItem() {
      return { ...this.combinedFindings[0], filePath: this.filePath };
    },
    inlineFindingsSubItems() {
      return this.findingsWithSeverity.slice(1, inlineFindingsCountThreshold);
    },
  },
};
</script>

<template>
  <div
    v-if="findingsWithSeverity.length"
    class="gl-z-index-1 gl-relative"
    @click="$emit('showInlineFindings')"
  >
    <div v-if="!inlineFindingsExpanded" class="gl-display-inline-flex">
      <span ref="inlineFindingsIcon" class="gl-z-index-200">
        <gl-icon
          :id="`inline-findings-${firstItem.filePath}:${firstItem.line}`"
          ref="firstInlineFindingsIcon"
          :key="firstItem.description"
          :size="16"
          :name="findingsWithSeverity[0].name"
          :class="findingsWithSeverity[0].class"
          class="gl-hover-cursor-pointer gl-relative gl-top-1 inline-findings-severity-icon gl-vertical-align-baseline!"
          @mouseenter="isHoveringFirstIcon = true"
          @mouseleave="isHoveringFirstIcon = false"
        />
      </span>
      <span class="inline-findings-transition-container gl-display-inline-flex">
        <transition-group name="icons">
          <!--
            The TransitionGroup Component will only apply its classes when first-level children are added/removed to the DOM.
            So to make TransitionGroup work there is no other way to use v-if-with-v-for in this case.
          -->
          <!-- eslint-disable vue/no-use-v-if-with-v-for -->
          <gl-icon
            v-for="(item, index) in inlineFindingsSubItems"
            v-if="isHoveringFirstIcon"
            :key="item.description"
            :name="inlineFindingsSubItems[index].name"
            :class="inlineFindingsSubItems[index].class"
            class="gl-hover-cursor-pointer gl-relative gl-top-1 inline-findings-severity-icon gl-absolute gl-left-0"
          />
          <!-- eslint-enable -->
        </transition-group>
        <transition name="more-count">
          <div
            v-if="showMoreCount"
            class="more-count gl-px-2 gl-w-auto gl-absolute gl-left-0 gl-relative gl-top-1"
            data-testid="inlineFindingsMoreCount"
          >
            <p class="gl-mb-0 gl-display-block gl-w-3 more-count-copy">{{ moreCount }}</p>
          </div>
        </transition>
      </span>
    </div>
    <button v-else class="inline-findings-collapse gl-mx-n2">
      <gl-icon :size="12" name="collapse" />
    </button>
    <!-- Only show tooltip when indicator is not expanded
      a) to stay consistent with other collapsed icon on the same page
      b) because the tooltip would be misaligned hence the negative margin
     -->
    <gl-tooltip v-if="!$props.inlineFindingsExpanded" :target="() => $refs.inlineFindingsIcon">
      <span v-if="codequality.length" class="gl-display-block">{{
        codeQualityTooltipTextCollapsed
      }}</span>
    </gl-tooltip>
  </div>
</template>
