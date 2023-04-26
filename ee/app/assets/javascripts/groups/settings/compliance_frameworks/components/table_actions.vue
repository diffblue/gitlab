<script>
import { GlButton, GlDropdown, GlDropdownItem, GlTooltipDirective } from '@gitlab/ui';

import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import {
  OPTIONS_BUTTON_LABEL,
  DELETE_BUTTON_LABEL,
  EDIT_BUTTON_LABEL,
  SET_DEFAULT_BUTTON_LABEL,
  REMOVE_DEFAULT_BUTTON_LABEL,
} from '../constants';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    framework: {
      type: Object,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  i18n: {
    optionsFramework: OPTIONS_BUTTON_LABEL,
    editFramework: EDIT_BUTTON_LABEL,
    deleteFramework: DELETE_BUTTON_LABEL,
    setDefaultFramework: SET_DEFAULT_BUTTON_LABEL,
    removeDefaultFramework: REMOVE_DEFAULT_BUTTON_LABEL,
  },
  computed: {
    isDefault() {
      return Boolean(this.framework.default);
    },
  },
  methods: {
    onEdit(event) {
      if (!this.glFeatures.manageComplianceFrameworksModalsRefactor) {
        return;
      }

      event.preventDefault();
      this.$emit('edit', this.framework);
    },
  },
};
</script>
<template>
  <div>
    <div v-if="framework.editPath" class="gl-display-flex">
      <gl-button
        v-gl-tooltip="$options.i18n.editFramework"
        :disabled="loading"
        :aria-label="$options.i18n.editFramework"
        :href="framework.editPath"
        data-testid="compliance-framework-edit-button"
        icon="pencil"
        category="tertiary"
        @click="onEdit"
      />
      <gl-dropdown
        v-gl-tooltip.hover.focus="$options.i18n.optionsFramework"
        right
        category="tertiary"
        :aria-label="$options.i18n.optionsFramework"
        icon="ellipsis_v"
        no-caret
        data-testid="compliance-framework-dropdown-button"
        :disabled="loading"
      >
        <gl-dropdown-item
          v-if="!isDefault"
          data-testid="compliance-framework-set-default-button"
          :aria-label="$options.i18n.setDefaultFramework"
          @click="$emit('setDefault', { framework, defaultVal: true })"
        >
          {{ $options.i18n.setDefaultFramework }}
        </gl-dropdown-item>
        <gl-dropdown-item
          v-if="isDefault"
          data-testid="compliance-framework-remove-default-button"
          :aria-label="$options.i18n.removeDefaultFramework"
          @click="$emit('removeDefault', { framework, defaultVal: false })"
        >
          {{ $options.i18n.removeDefaultFramework }}
        </gl-dropdown-item>
        <gl-dropdown-item
          v-if="!isDefault"
          class="gl-text-red-500"
          data-testid="compliance-framework-delete-button"
          :aria-label="$options.i18n.deleteFramework"
          @click="$emit('delete', framework)"
        >
          {{ $options.i18n.deleteFramework }}
        </gl-dropdown-item>
      </gl-dropdown>
    </div>
  </div>
</template>
