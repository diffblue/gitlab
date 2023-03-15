<script>
import { GlSprintf, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    dastProfilesMessage: s__(
      'ScanExecutionPolicy|scanner profile %{scannerProfile} and site profile %{siteProfile}',
    ),
    selectedScannerProfilePlaceholder: s__('ScanExecutionPolicy|Select scanner profile'),
    selectedSiteProfilePlaceholder: s__('ScanExecutionPolicy|Select site profile'),
  },
  name: 'GroupDastProfileSelector',
  components: {
    GlSprintf,
    GlFormGroup,
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
  <div class="gl-display-flex gl-align-items-center gl-gap-3">
    <gl-sprintf :message="$options.i18n.dastProfilesMessage">
      <template #scannerProfile>
        <gl-form-group
          class="gl-mb-0"
          :label="s__('ScanExecutionPolicy|Scanner profile')"
          label-for="scanner-profile"
          label-sr-only
        >
          <gl-form-input
            id="scanner-profile"
            v-model="scannerProfile"
            :placeholder="$options.i18n.selectedScannerProfilePlaceholder"
            data-testid="scan-profile-selection"
          />
        </gl-form-group>
      </template>
      <template #siteProfile>
        <gl-form-group
          class="gl-mb-0"
          :label="s__('ScanExecutionPolicy|Site profile')"
          label-for="site-profile"
          label-sr-only
        >
          <gl-form-input
            id="site-profile"
            v-model="siteProfile"
            :placeholder="$options.i18n.selectedSiteProfilePlaceholder"
            data-testid="site-profile-selection"
          />
        </gl-form-group>
      </template>
    </gl-sprintf>
  </div>
</template>
