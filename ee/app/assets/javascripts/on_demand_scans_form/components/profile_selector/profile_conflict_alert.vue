<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export default {
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
  },
  dastSiteValidationDocsPath: helpPagePath('user/application_security/dast/index', {
    anchor: 'site-profile-validation',
  }),
  i18n: {
    title: s__('DastProfiles|You cannot run an active scan against an unvalidated site.'),
    message: s__(
      'DastProfiles|You can either choose a passive scan or validate the target site from the site profile management page. %{docsLinkStart}Learn more about site validation.%{docsLinkEnd}',
    ),
  },
};
</script>

<template>
  <gl-alert :title="$options.i18n.title" :dismissible="false" variant="danger">
    <gl-sprintf :message="$options.i18n.message">
      <template #docsLink="{ content }">
        <gl-link :href="$options.dastSiteValidationDocsPath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
