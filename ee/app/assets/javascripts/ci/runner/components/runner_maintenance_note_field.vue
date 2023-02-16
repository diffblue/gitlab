<script>
import { GlFormGroup, GlFormTextarea } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    GlFormGroup,
    GlFormTextarea,
  },
  mixins: [glFeatureFlagMixin()],
  inheritAttrs: false,
  computed: {
    shouldRender() {
      return this.glFeatures.runnerMaintenanceNote;
    },
  },
};
</script>
<template>
  <gl-form-group
    v-if="shouldRender"
    data-testid="runner-field-maintenance-note"
    :label="s__('Runners|Maintenance note')"
    label-for="runner-maintenance-note"
    :label-description="s__('Runners|Only administrators can view this.')"
    :description="s__('Runners|Add notes such as the runner owner or what it should be used for.')"
  >
    <gl-form-textarea
      id="runner-maintenance-note"
      :no-resize="false"
      name="maintenance-note"
      v-bind="$attrs"
      v-on="$listeners"
    />
  </gl-form-group>
</template>
