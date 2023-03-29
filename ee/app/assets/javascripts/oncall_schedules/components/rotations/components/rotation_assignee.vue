<script>
import { GlAvatar, GlPopover } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { formatDate } from '~/lib/utils/datetime_utility';
import { truncate } from '~/lib/utils/text_utility';
import { __, sprintf } from '~/locale';

export const SHIFT_WIDTHS = {
  md: 100,
  sm: 75,
  xs: 20,
};

const ROTATION_CENTER_CLASS = 'gl-rounded-base gl-display-flex gl-align-items-center';
export const TIME_DATE_FORMAT = 'mmmm d, yyyy, HH:MM ("UTC:" o)';

export default {
  ROTATION_CENTER_CLASS,
  components: {
    GlAvatar,
    GlPopover,
  },
  props: {
    assignee: {
      type: Object,
      required: true,
    },
    startsAt: {
      type: String,
      required: true,
    },
    endsAt: {
      type: String,
      required: true,
    },
    containerStyle: {
      type: Object,
      required: true,
    },
    color: {
      type: Object,
      required: true,
    },
  },
  data() {
    const { colorWeight, backgroundStyle, textClass } = this.color;

    return {
      colorWeight,
      backgroundStyle,
      textClass,
      shiftWidth: parseInt(this.containerStyle.width, 10),
    };
  },
  computed: {
    assigneeName() {
      if (this.shiftWidth <= SHIFT_WIDTHS.md) {
        return truncate(this.assignee.user.username, 3);
      }

      return this.assignee.user.username;
    },
    endsAtString() {
      return sprintf(__('Ends: %{endsAt}'), {
        endsAt: `${formatDate(this.endsAt, TIME_DATE_FORMAT)}`,
      });
    },
    rotationAssigneeUniqueID() {
      return uniqueId('rotation-assignee-');
    },
    hasRotationMobileViewAvatar() {
      return this.shiftWidth <= SHIFT_WIDTHS.xs;
    },
    hasRotationMobileViewText() {
      return this.shiftWidth <= SHIFT_WIDTHS.sm;
    },
    startsAtString() {
      return sprintf(__('Starts: %{startsAt}'), {
        startsAt: `${formatDate(this.startsAt, TIME_DATE_FORMAT)}`,
      });
    },
  },
};
</script>

<template>
  <div
    class="rotation-asignee-container gl-absolute gl-h-7 gl-mt-3 gl-pr-1"
    :style="containerStyle"
  >
    <div
      :id="rotationAssigneeUniqueID"
      class="gl-h-6"
      :style="backgroundStyle"
      :class="[
        $options.ROTATION_CENTER_CLASS,
        { 'gl-justify-content-center': hasRotationMobileViewText },
      ]"
      data-testid="rotation-assignee"
    >
      <div
        :class="[
          textClass,
          $options.ROTATION_CENTER_CLASS,
          { 'gl-pl-2': !hasRotationMobileViewText },
        ]"
      >
        <gl-avatar v-if="!hasRotationMobileViewAvatar" :src="assignee.user.avatarUrl" :size="16" />
        <span
          v-if="!hasRotationMobileViewText"
          class="gl-ml-2 gl-line-height-24"
          data-testid="rotation-assignee-name"
          >{{ assigneeName }}</span
        >
      </div>
    </div>
    <gl-popover
      :target="rotationAssigneeUniqueID"
      :title="assignee.user.username"
      placement="right"
    >
      <p class="gl-m-0" data-testid="rotation-assignee-starts-at">
        {{ startsAtString }}
      </p>
      <p class="gl-m-0" data-testid="rotation-assignee-ends-at">
        {{ endsAtString }}
      </p>
    </gl-popover>
  </div>
</template>
