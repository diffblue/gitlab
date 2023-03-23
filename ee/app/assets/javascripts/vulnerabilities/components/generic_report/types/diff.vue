<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';

import { VIEW_TYPES, LINE_TYPES } from './constants';
import { createDiffData } from './diff_utils';

export default {
  components: {
    GlButtonGroup,
    GlButton,
  },
  props: {
    before: {
      type: String,
      required: true,
    },
    after: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      view: VIEW_TYPES.DIFF,
    };
  },
  viewTypes: {
    DIFF: VIEW_TYPES.DIFF,
    BEFORE: VIEW_TYPES.BEFORE,
    AFTER: VIEW_TYPES.AFTER,
  },
  computed: {
    diffData() {
      return createDiffData(this.before, this.after);
    },
    visibleDiffData() {
      return this.diffData.filter(this.shouldShowLine);
    },
    isDiffView() {
      return this.view === this.$options.viewTypes.DIFF;
    },
    isBeforeView() {
      return this.view === this.$options.viewTypes.BEFORE;
    },
    isAfterView() {
      return this.view === this.$options.viewTypes.AFTER;
    },
  },
  methods: {
    shouldShowLine(line) {
      return (
        this.view === VIEW_TYPES.DIFF ||
        line.type === LINE_TYPES.NORMAL ||
        (line.type === LINE_TYPES.REMOVED && this.isBeforeView) ||
        (line.type === LINE_TYPES.ADDED && this.isAfterView)
      );
    },
    changeClass(change) {
      return {
        normal: '',
        added: 'new',
        removed: 'old',
      }[change.type];
    },
    changeClassIDiff(action) {
      if (action.removed || action.added) {
        return 'idiff';
      }
      return '';
    },
    setView(viewType) {
      this.view = viewType;
    },
  },
  userColorScheme: window.gon?.user_color_scheme,
};
</script>

<template>
  <div class="gl-rounded-base gl-border-solid gl-border-1 gl-border-gray-100">
    <div class="gl-overflow-hidden gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-p-3">
      <gl-button-group class="gl-display-flex gl-float-right">
        <gl-button
          :class="{ selected: isDiffView }"
          data-testid="diffButton"
          @click="setView($options.viewTypes.DIFF)"
        >
          {{ s__('GenericReport|Diff') }}
        </gl-button>
        <gl-button
          :class="{ selected: isBeforeView }"
          data-testid="beforeButton"
          @click="setView($options.viewTypes.BEFORE)"
        >
          {{ s__('GenericReport|Before') }}
        </gl-button>
        <gl-button
          :class="{ selected: isAfterView }"
          data-testid="afterButton"
          @click="setView($options.viewTypes.AFTER)"
        >
          {{ s__('GenericReport|After') }}
        </gl-button>
      </gl-button-group>
    </div>
    <table class="code" :class="$options.userColorScheme">
      <tr
        v-for="(line, idx) in visibleDiffData"
        :key="idx"
        :class="changeClass(line)"
        class="line_holder"
        data-testid="diffLine"
      >
        <td class="diff-line-num gl-border-t-0 gl-border-b-0" :class="changeClass(line)">
          {{ line.oldLine }}
        </td>
        <td class="diff-line-num gl-border-t-0 gl-border-b-0" :class="changeClass(line)">
          {{ line.newLine }}
        </td>
        <td data-testid="diffContent" class="line_content" :class="changeClass(line)">
          <span
            v-for="(action, actionIdx) in line.actions"
            :key="actionIdx"
            class="left right"
            :class="changeClassIDiff(action)"
            >{{ action.value }}</span
          >
        </td>
      </tr>
    </table>
  </div>
</template>
