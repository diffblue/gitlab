<script>
import { GlButton, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { STAGE_SORT_DIRECTION } from './constants';

export default {
  i18n: {
    moveDownLabel: __('Move down'),
    moveUpLabel: __('Move up'),
  },
  name: 'StageFieldActions',
  components: {
    GlButton,
    GlButtonGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    index: {
      type: Number,
      required: true,
    },
    stageCount: {
      type: Number,
      required: true,
    },
    canRemove: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    lastStageIndex() {
      return this.stageCount - 1;
    },
    isFirstActiveStage() {
      return this.index === 0;
    },
    isLastActiveStage() {
      return this.index === this.lastStageIndex;
    },
    hideActionEvent() {
      return this.canRemove ? 'remove' : 'hide';
    },
    hideActionTooltip() {
      return this.canRemove ? __('Remove') : __('Hide');
    },
    hideActionIcon() {
      return this.canRemove ? 'remove' : 'eye-slash';
    },
    hideActionTestId() {
      return `stage-action-${this.canRemove ? 'remove' : 'hide'}-${this.index}`;
    },
  },
  STAGE_SORT_DIRECTION,
};
</script>
<template>
  <div>
    <gl-button-group class="gl-pr-2">
      <gl-button
        v-gl-tooltip
        :data-testid="`stage-action-move-down-${index}`"
        :disabled="isLastActiveStage"
        icon="arrow-down"
        :title="$options.i18n.moveDownLabel"
        :aria-label="$options.i18n.moveDownLabel"
        @click="$emit('move', { index, direction: $options.STAGE_SORT_DIRECTION.DOWN })"
      />
      <gl-button
        v-gl-tooltip
        :data-testid="`stage-action-move-up-${index}`"
        :disabled="isFirstActiveStage"
        icon="arrow-up"
        :title="$options.i18n.moveUpLabel"
        :aria-label="$options.i18n.moveUpLabel"
        @click="$emit('move', { index, direction: $options.STAGE_SORT_DIRECTION.UP })"
      />
    </gl-button-group>
    <gl-button
      v-gl-tooltip
      :title="hideActionTooltip"
      :aria-label="hideActionTooltip"
      :data-testid="hideActionTestId"
      :icon="hideActionIcon"
      @click="$emit(hideActionEvent, index)"
    />
  </div>
</template>
