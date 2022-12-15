<script>
import { GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import {
  sprintfWorkItem,
  i18n,
  I18N_WORK_ITEM_ERROR_UPDATING,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import { getWorkItemQuery } from '~/work_items/utils';

export default {
  inputId: 'progress-widget-input',
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
    fetchByIid: {
      type: Boolean,
      required: false,
      default: false,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
    };
  },
  apollo: {
    workItem: {
      query() {
        return getWorkItemQuery(this.fetchByIid);
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return this.fetchByIid ? data.workspace.workItems.nodes[0] : data.workItem;
      },
      skip() {
        return !this.queryVariables.id && !this.queryVariables.iid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
    },
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
    isOkrsEnabled() {
      return this.hasOkrsFeature && this.glFeatures.okrsMvc;
    },
  },
  methods: {
    blurInput() {
      this.$refs.input.$el.blur();
    },
    handleFocus() {
      this.isEditing = true;
    },
    updateProgress(event) {
      if (!this.canUpdate) return;
      this.isEditing = false;

      const progress = Number(event.target.value);
      if (this.progress === progress) {
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
                progress: event.target.value === '' ? null : progress,
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
  },
};
</script>

<template>
  <gl-form v-if="isOkrsEnabled" @submit.prevent="blurInput">
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
        min="0"
        max="100"
        class="gl-hover-border-gray-200! gl-border-solid! gl-border-white!"
        :class="{ 'hide-spinners gl-shadow-none!': !isEditing }"
        :placeholder="placeholder"
        :readonly="!canUpdate"
        size="sm"
        type="number"
        :value="progress"
        @blur="updateProgress"
        @focus="handleFocus"
      />
    </gl-form-group>
  </gl-form>
</template>
