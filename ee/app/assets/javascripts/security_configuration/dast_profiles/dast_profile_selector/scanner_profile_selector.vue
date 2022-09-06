<script>
import { GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import ScannerProfileSummary from 'ee/security_configuration/dast_profiles/dast_profile_selector/scanner_profile_summary.vue';

import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import EmptyState from 'ee/security_configuration/dast_profiles/dast_profile_selector/empty_state.vue';

const SCANNER_PROFILE_INFO = helpPagePath('user/application_security/dast/index', {
  anchor: 'scanner-profile',
});

export default {
  name: 'DastScannerProfileSelector',
  i18n: {
    emptyStateHeader: s__('DastProfiles|Scanner profile'),
    emptyStateContentHeader: s__('DastProfiles|No scanner profile selected'),
    emptyStateContent: s__('DastProfiles|Select a scanner profile to run a DAST scan'),
    selectProfileButton: s__('DastProfiles|Select scanner profile'),
    changeProfileButton: s__('DastProfiles|Change scanner profile'),
    scannerProfileDescription: s__(
      'DastProfiles|A scanner profile defines the configuration details of a security scanner. %{linkStart}Learn more%{linkEnd}.',
    ),
  },
  SCANNER_PROFILE_INFO,
  components: {
    EmptyState,
    GlButton,
    GlLink,
    GlSprintf,
    ScannerProfileSummary,
  },
  props: {
    selectedProfile: {
      type: Object,
      required: false,
      default: null,
    },
    profileIdInUse: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    hasScannerProfileSelector() {
      return Boolean(this.selectedProfile);
    },
    actionButtonText() {
      return this.hasScannerProfileSelector
        ? this.$options.i18n.changeProfileButton
        : this.$options.i18n.selectProfileButton;
    },
    isProfileInUse() {
      return this.selectedProfile?.id === this.profileIdInUse;
    },
  },

  methods: {
    openDrawer() {
      this.$emit('open-drawer');
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-4">
      <h4 class="gl-font-lg gl-mt-0 gl-mb-2">
        {{ $options.i18n.emptyStateHeader }}
      </h4>
      <p>
        <gl-sprintf :message="$options.i18n.scannerProfileDescription">
          <template #link="{ content }">
            <gl-link :href="$options.SCANNER_PROFILE_INFO">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>

    <empty-state v-if="!hasScannerProfileSelector" class="gl-mb-4">
      <template #header>
        {{ $options.i18n.emptyStateContentHeader }}
      </template>
      <template #content>
        {{ $options.i18n.emptyStateContent }}
      </template>
    </empty-state>

    <scanner-profile-summary
      v-else
      :profile="selectedProfile"
      :is-profile-in-use="isProfileInUse"
      class="gl-mb-4"
      @edit="$emit('edit')"
    />

    <gl-button
      data-testid="select-profile-action-btn"
      variant="confirm"
      category="secondary"
      @click="openDrawer"
    >
      {{ actionButtonText }}
    </gl-button>
  </div>
</template>
