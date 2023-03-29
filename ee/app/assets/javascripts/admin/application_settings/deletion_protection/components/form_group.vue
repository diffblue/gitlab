<script>
import {
  GlFormGroup,
  GlFormInputGroup,
  GlFormRadio,
  GlFormInput,
  GlLink,
  GlFormSelect,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { I18N_DELETION_PROTECTION } from '../constants';

export default {
  components: {
    GlFormGroup,
    GlFormInputGroup,
    GlFormInput,
    GlLink,
    GlFormRadio,
    GlFormSelect,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    deletionAdjournedPeriod: {
      type: Number,
      required: true,
    },
    delayedGroupDeletion: {
      type: Boolean,
      required: true,
    },
    delayedProjectDeletion: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      formData: {
        deletionAdjournedPeriod: this.deletionAdjournedPeriod,
        delayedProjectDeletion: this.delayedProjectDeletion,
        delayedGroupDeletion: this.delayedGroupDeletion,
      },
    };
  },
  computed: {
    delayedDeletionDisabled() {
      if (this.isAlwaysPerformDelayedDeletionFeatureFlagEnabled) {
        return false;
      }

      return !this.formData.delayedGroupDeletion;
    },
    inputGroupTextClass() {
      return this.delayedDeletionDisabled
        ? 'gl-border-gray-100 gl-bg-gray-10 gl-text-gray-400'
        : '';
    },
    isAlwaysPerformDelayedDeletionFeatureFlagEnabled() {
      return this.glFeatures.alwaysPerformDelayedDeletion;
    },
    helpText() {
      if (this.isAlwaysPerformDelayedDeletionFeatureFlagEnabled) {
        return this.$options.i18n.helpTextFeatureFlagEnabled;
      }

      return this.$options.i18n.helpText;
    },
  },
  i18n: I18N_DELETION_PROTECTION,
  selectOptions: [
    { value: false, text: I18N_DELETION_PROTECTION.groupsOnly },
    { value: true, text: I18N_DELETION_PROTECTION.groupsAndProjects },
  ],
  helpPath: helpPagePath('user/admin_area/settings/visibility_and_access_controls', {
    anchor: 'delayed-project-deletion',
  }),
};
</script>
<template>
  <gl-form-group :label="$options.i18n.heading">
    <p class="text-muted" data-testid="help-text">
      <span>{{ helpText }}</span>
      <gl-link :href="$options.helpPath" target="_blank">{{ $options.i18n.learnMore }}</gl-link>
    </p>
    <div
      data-testid="keep-deleted"
      class="gl-display-flex gl-flex-direction-row gl-align-items-baseline gl-mb-3"
    >
      <template v-if="!isAlwaysPerformDelayedDeletionFeatureFlagEnabled">
        <gl-form-radio
          v-model="formData.delayedGroupDeletion"
          name="application_setting[delayed_group_deletion]"
          class="gl-mr-3"
          :value="true"
          >{{ $options.i18n.keepDeleted }}</gl-form-radio
        >
        <gl-form-select
          name="application_setting[delayed_project_deletion]"
          :disabled="delayedDeletionDisabled"
          :value="formData.delayedProjectDeletion"
          :options="$options.selectOptions"
          class="gl-mr-3 gl-w-20 gl-py-0 gl-px-2 gl-h-6!"
        />
        <span class="gl-mr-3">{{ $options.i18n.for }}</span>
      </template>
      <gl-form-input-group class="gl-w-auto">
        <gl-form-input
          v-model="formData.deletionAdjournedPeriod"
          name="application_setting[deletion_adjourned_period]"
          size="sm"
          type="number"
          class="gl-py-2 gl-px-3 gl-w-11! gl-h-6!"
          :min="1"
          :max="90"
          :disabled="delayedDeletionDisabled"
        />
        <template #append>
          <div :class="inputGroupTextClass" class="input-group-text gl-h-6!">
            {{ $options.i18n.days }}
          </div>
        </template>
      </gl-form-input-group>
    </div>
    <gl-form-radio
      v-if="!isAlwaysPerformDelayedDeletionFeatureFlagEnabled"
      v-model="formData.delayedGroupDeletion"
      data-testid="delete-immediately"
      name="application_setting[delayed_group_deletion]"
      :value="false"
      >{{ $options.i18n.deleteImmediately }}</gl-form-radio
    >
    <!-- When delayed deletion is disabled then delayedProjectDeletion must be set to false. -->
    <input
      v-if="delayedDeletionDisabled"
      data-testid="hidden-input"
      hidden
      value="false"
      name="application_setting[delayed_project_deletion]"
    />
  </gl-form-group>
</template>
