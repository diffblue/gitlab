<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
  },
  inject: ['siteProfilesLibraryPath'],
  dastSiteValidationDocsPath: helpPagePath('user/application_security/dast/index', {
    anchor: 'site-profile-validation',
  }),
};
</script>

<template>
  <gl-alert
    :title="s__('DastProfiles|You cannot run an active scan against an unvalidated site.')"
    :dismissible="false"
    :primary-button-text="s__('DastProfiles|Manage site profiles')"
    :primary-button-link="siteProfilesLibraryPath"
    variant="danger"
  >
    <gl-sprintf
      :message="
        s__(
          'DastProfiles|You can either choose a passive scan or validate the target site in your chosen site profile. %{docsLinkStart}Learn more about site validation.%{docsLinkEnd}',
        )
      "
    >
      <template #docsLink="{ content }">
        <gl-link :href="$options.dastSiteValidationDocsPath">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
