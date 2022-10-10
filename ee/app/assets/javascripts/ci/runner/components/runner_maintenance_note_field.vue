<script>
import { GlFormGroup, GlFormTextarea } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlFormGroup,
    GlFormTextarea,
  },
  mixins: [glFeatureFlagMixin()],
  computed: {
    shouldRender() {
      return this.glFeatures.runnerMaintenanceNote;
    },
  },
};
</script>
<template>
  <div v-if="shouldRender">
    <gl-form-group
      data-testid="runner-field-maintenance-note"
      :label="s__('Runners|Maintenance note')"
      :description="
        s__('Runners|Add notes, like who owns the runner or what it should be used for.')
      "
    >
      <gl-form-textarea :no-resize="false" v-bind="$attrs" v-on="$listeners" />
    </gl-form-group>
  </div>
</template>
