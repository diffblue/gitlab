<script>
import { GlForm, GlToggle, GlFormGroup, GlFormTextarea, GlButton, GlLoadingIcon } from '@gitlab/ui';
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import { mapComputed } from '~/vuex_shared/bindings';

export default {
  name: 'MaintenanceModeSettingsApp',
  i18n: {
    toggleLabel: __('Enable maintenance mode'),
    toggleHelpText: __(
      'Non-admin users are restricted to read-only access, in both GitLab UI and API.',
    ),
    bannerMessagePlaceholder: __('GitLab is undergoing maintenance'),
    buttonText: __('Save changes'),
    bannerLabel: __('Banner message'),
  },
  components: {
    GlForm,
    GlToggle,
    GlFormGroup,
    GlFormTextarea,
    GlButton,
    GlLoadingIcon,
  },
  computed: {
    ...mapState(['loading']),
    ...mapComputed([
      { key: 'maintenanceEnabled', updateFn: 'setMaintenanceEnabled' },
      { key: 'bannerMessage', updateFn: 'setBannerMessage' },
    ]),
  },
  methods: {
    ...mapActions(['updateMaintenanceModeSettings']),
  },
};
</script>
<template>
  <section>
    <gl-loading-icon v-if="loading" size="xl" />
    <gl-form v-else @submit.prevent="updateMaintenanceModeSettings">
      <div class="gl-display-flex gl-align-items-center gl-mb-4">
        <gl-toggle
          v-model="maintenanceEnabled"
          :label="$options.i18n.toggleLabel"
          label-position="hidden"
        />
        <div class="gl-ml-3">
          <p class="gl-mb-0">{{ $options.i18n.toggleLabel }}</p>
          <p class="gl-mb-0 gl-text-gray-500">
            {{ $options.i18n.toggleHelpText }}
          </p>
        </div>
      </div>
      <gl-form-group :label="$options.i18n.bannerLabel" label-for="maintenanceBannerMessage">
        <gl-form-textarea
          id="maintenanceBannerMessage"
          v-model="bannerMessage"
          :placeholder="$options.i18n.bannerMessagePlaceholder"
        />
      </gl-form-group>
      <gl-button variant="confirm" type="submit">{{ $options.i18n.buttonText }}</gl-button>
    </gl-form>
  </section>
</template>
