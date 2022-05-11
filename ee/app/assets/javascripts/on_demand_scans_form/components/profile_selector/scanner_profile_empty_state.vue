<script>
import { GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import EmptyState from './empty_state.vue';

const SCANNER_PROFILE_INFO = helpPagePath('user/application_security/dast/index', {
  anchor: 'scanner-profile',
});

export default {
  SCANNER_PROFILE_INFO,
  i18n: {
    emptyStateHeader: s__('DastProfiles|Scanner Profile'),
    emptyStateContentHeader: s__('DastProfiles|No scanner profile selected'),
    emptyStateContent: s__('DastProfiles|Select a scanner profile to run a DAST scan'),
    selectProfileButton: s__('DastProfiles|Select scanner profile'),
    scannerProfileDescription: s__(
      'DastProfiles|Scanner profiles define the configuration details of a security scanner. %{linkStart}Learn more%{linkEnd}.',
    ),
  },
  components: {
    EmptyState,
    GlButton,
    GlLink,
    GlSprintf,
  },
};
</script>

<template>
  <div>
    <empty-state>
      <template #main-header>
        {{ $options.i18n.emptyStateHeader }}
      </template>
      <template #header-description>
        <gl-sprintf :message="$options.i18n.scannerProfileDescription">
          <template #link="{ content }">
            <gl-link :href="$options.SCANNER_PROFILE_INFO">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
      <template #header>
        {{ $options.i18n.emptyStateContentHeader }}
      </template>
      <template #content>
        {{ $options.i18n.emptyStateContent }}
      </template>
    </empty-state>

    <gl-button
      variant="confirm"
      category="secondary"
      data-testid="create-scanner-profile-link"
      @click="$emit('click')"
    >
      {{ $options.i18n.selectProfileButton }}
    </gl-button>
  </div>
</template>
