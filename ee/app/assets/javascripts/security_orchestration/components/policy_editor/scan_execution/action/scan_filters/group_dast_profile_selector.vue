<script>
import { GlFormInput } from '@gitlab/ui';
import GenericBaseLayoutComponent from 'ee/security_orchestration/components/policy_editor/generic_base_layout_component.vue';
import { DAST_PROFILE_I18N } from './constants';

export default {
  i18n: { ...DAST_PROFILE_I18N },
  name: 'GroupDastProfileSelector',
  components: {
    GenericBaseLayoutComponent,
    GlFormInput,
  },
  props: {
    savedScannerProfileName: {
      type: String,
      required: false,
      default: null,
    },
    savedSiteProfileName: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      siteProfile: this.savedSiteProfileName ?? '',
      scannerProfile: this.savedScannerProfileName ?? '',
    };
  },
  watch: {
    scannerProfile(value) {
      this.$emit('set-profile', { scannerProfile: value, siteProfile: this.siteProfile });
    },
    siteProfile(value) {
      this.$emit('set-profile', { siteProfile: value, scannerProfile: this.scannerProfile });
    },
  },
};
</script>

<template>
  <div class="gl-w-full">
    <generic-base-layout-component
      class="gl-w-full gl-bg-white gl-mb-3"
      :show-remove-button="false"
    >
      <template #selector>
        <label class="gl-mb-0 gl-mr-4" for="scanner-profile">
          {{ $options.i18n.scanLabel }}
        </label>
      </template>
      <template #content>
        <gl-form-input
          id="scanner-profile"
          v-model="scannerProfile"
          class="gl-w-30p"
          :placeholder="$options.i18n.selectedScannerProfilePlaceholder"
          data-testid="scan-profile-selection"
        />
      </template>
    </generic-base-layout-component>
    <generic-base-layout-component class="gl-w-full gl-bg-white" :show-remove-button="false">
      <template #selector>
        <label class="gl-mb-0 gl-mr-4" for="site-profile">
          {{ $options.i18n.siteLabel }}
        </label>
      </template>
      <template #content>
        <gl-form-input
          id="site-profile"
          v-model="siteProfile"
          class="gl-w-30p"
          :placeholder="$options.i18n.selectedSiteProfilePlaceholder"
          data-testid="site-profile-selection"
        />
      </template>
    </generic-base-layout-component>
  </div>
</template>
