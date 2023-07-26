<script>
import { GlFormGroup, GlFormInput, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { I18N_DELETION_PROTECTION } from '../constants';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlLink,
  },
  props: {
    deletionAdjournedPeriod: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      formData: {
        deletionAdjournedPeriod: this.deletionAdjournedPeriod,
      },
    };
  },
  i18n: I18N_DELETION_PROTECTION,
  helpPath: helpPagePath('administration/settings/visibility_and_access_controls', {
    anchor: 'delayed-project-deletion',
  }),
  inputId: 'application_setting_deletion_adjourned_period',
};
</script>
<template>
  <gl-form-group :label="$options.i18n.label" :label-for="$options.inputId">
    <template #label-description>
      <span>{{ $options.i18n.helpText }}</span>
      <gl-link :href="$options.helpPath" target="_blank">{{ $options.i18n.learnMore }}</gl-link>
    </template>
    <div class="gl-display-flex gl-align-items-center">
      <gl-form-input
        :id="$options.inputId"
        v-model="formData.deletionAdjournedPeriod"
        name="application_setting[deletion_adjourned_period]"
        size="xs"
        type="number"
        :min="1"
        :max="90"
      />
      <span class="gl-ml-3">{{ $options.i18n.days }}</span>
    </div>
  </gl-form-group>
</template>
