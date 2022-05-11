<script>
import { GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import EmptyState from './empty_state.vue';

const SITE_PROFILE_INFO = helpPagePath('user/application_security/dast/index', {
  anchor: 'site-profile',
});

export default {
  SITE_PROFILE_INFO,
  i18n: {
    emptyStateHeader: s__('DastProfiles|Site Profile'),
    emptyStateContentHeader: s__('DastProfiles|No site profile selected'),
    emptyStateContent: s__('DastProfiles|Select a site profile to run a DAST scan'),
    selectProfileButton: s__('DastProfiles|Select site profile'),
    siteProfileDescription: s__(
      'DastProfiles|Site profiles define the attributes and configuration details of your deployed application, website, or API. %{linkStart}Learn more%{linkEnd}.',
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
      <template #main-header>{{ $options.i18n.emptyStateHeader }}</template>
      <template #header-description>
        <gl-sprintf :message="$options.i18n.siteProfileDescription">
          <template #link="{ content }">
            <gl-link :href="$options.SITE_PROFILE_INFO">{{ content }}</gl-link>
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
      data-testid="create-site-profile-link"
      @click="$emit('click')"
    >
      {{ $options.i18n.selectProfileButton }}
    </gl-button>
  </div>
</template>
