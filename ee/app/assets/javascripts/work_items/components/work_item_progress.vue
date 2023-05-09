<script>
import { GlForm, GlFormGroup, GlFormInput, GlTooltipDirective } from '@gitlab/ui';
import { isNumber } from 'lodash';
import * as Sentry from '@sentry/browser';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import {
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_UPDATING,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inputId: 'progress-widget-input',
  minValue: 0,
  maxValue: 100,
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
  },
  mixins: [Tracking.mixin(), glFeatureFlagMixin()],
  inject: ['hasOkrsFeature'],
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    progress: {
      type: Number,
      required: false,
      default: undefined,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
      localProgress: this.progress,
    };
  },
  computed: {
    placeholder() {
      return this.canUpdate && this.isEditing ? __('Enter a number') : __('None');
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_progress',
        property: `type_${this.workItemType}`,
      };
    },
    showPercent() {
      return !this.isEditing && isNumber(this.localProgress);
    },
    isOkrsEnabled() {
      return this.hasOkrsFeature && this.glFeatures.okrsMvc;
    },
  },
  watch: {
    progress(newValue) {
      this.localProgress = newValue;
    },
  },
  methods: {
    isValidProgress(progress) {
      return (
        Number.isInteger(progress) &&
        progress >= this.$options.minValue &&
        progress <= this.$options.maxValue
      );
    },
    blurInput() {
      this.$refs.input.$el.blur();
    },
    handleFocus() {
      this.isEditing = true;
    },
    updateProgress(event) {
      if (!this.canUpdate) return;
      this.isEditing = false;

      const { valueAsNumber } = event.target;

      if (
        !this.canUpdate ||
        valueAsNumber === this.progress ||
        !this.isValidProgress(valueAsNumber)
      ) {
        this.localProgress = this.progress;
        return;
      }

      this.track('updated_progress');
      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              progressWidget: {
                progress: valueAsNumber,
              },
            },
          },
        })
        .then(({ data }) => {
          if (data.workItemUpdate.errors.length) {
            throw new Error(data.workItemUpdate.errors.join('\n'));
          }
        })
        .catch((error) => {
          const msg = sprintfWorkItem(I18N_WORK_ITEM_ERROR_UPDATING, this.workItemType);
          this.$emit('error', msg);
          Sentry.captureException(error);
        });
    },
    getProgressTooltip() {
      return this.glFeatures.okrAutomaticRollups && this.workItemType === __('Objective')
        ? __(
            'This field is auto-calculated based on the Progress score of its direct children. You can overwrite this value but it will be replaced by the auto-calcualtion anytime the Progress score of its direct children is updated.',
          )
        : '';
    },
  },
};
</script>

<template>
  <gl-form v-if="isOkrsEnabled" data-testid="work-item-progress" @submit.prevent="blurInput">
    <gl-form-group
      class="gl-align-items-center"
      :label="__('Progress')"
      label-for="progress-widget-input"
      label-class="gl-pb-0! gl-overflow-wrap-break"
      label-cols="3"
      label-cols-lg="2"
    >
      <gl-form-input
        id="progress-widget-input"
        ref="input"
        v-model="localProgress"
        v-gl-tooltip
        :title="getProgressTooltip"
        :min="$options.minValue"
        :max="$options.maxValue"
        data-testid="work-item-progress-input"
        class="gl-hover-border-gray-200! gl-border-solid! gl-border-white!"
        :class="{ 'hide-spinners gl-shadow-none!': !isEditing }"
        :placeholder="placeholder"
        :readonly="!canUpdate"
        size="sm"
        type="number"
        @blur="updateProgress"
        @focus="handleFocus"
      />
      <span
        v-if="showPercent"
        class="gl-mx-4 gl-my-3 gl-absolute gl-top-0 gl-bg-white gl-border gl-border-white gl-line-height-normal"
        data-testid="progress-displayed-value"
      >
        {{ localProgress }}%
      </span>
    </gl-form-group>
  </gl-form>
</template>
