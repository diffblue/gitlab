<script>
import { GlAlert, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import sastCiConfigurationQuery from '../graphql/sast_ci_configuration.query.graphql';
import ConfigurationForm from './configuration_form.vue';

export default {
  components: {
    ConfigurationForm,
    GlAlert,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    sastDocumentationPath: {
      from: 'sastDocumentationPath',
      default: '',
    },
    projectPath: {
      from: 'projectPath',
      default: '',
    },
  },
  apollo: {
    sastCiConfiguration: {
      query: sastCiConfigurationQuery,
      variables() {
        return {
          fullPath: this.projectPath,
        };
      },
      update({ project }) {
        return project?.sastCiConfiguration;
      },
      result({ loading }) {
        if (!loading && !this.sastCiConfiguration) {
          this.onError();
        }
      },
      error() {
        this.onError();
      },
    },
  },
  data() {
    return {
      sastCiConfiguration: null,
      hasLoadingError: false,
      showFeedbackAlert: true,
    };
  },
  methods: {
    dismissFeedbackAlert() {
      this.showFeedbackAlert = false;
    },
    onError() {
      this.hasLoadingError = true;
    },
  },
  i18n: {
    feedbackAlertMessage: s__(`
      As we continue to build more features for SAST, we'd love your feedback
      on the SAST configuration feature in %{linkStart}this issue%{linkEnd}.`),
    helpText: s__(
      `SecurityConfiguration|Customize common SAST settings to suit your
      requirements. Configuration changes made here override those provided by
      GitLab and are excluded from updates. For details of more advanced
      configuration options, see the %{linkStart}GitLab SAST documentation%{linkEnd}.`,
    ),
    loadingErrorText: s__(
      `SecurityConfiguration|Could not retrieve configuration data. Please
      refresh the page, or try again later.`,
    ),
  },
  feedbackIssue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/225991',
};
</script>

<template>
  <article>
    <gl-alert
      v-if="showFeedbackAlert"
      data-testid="feedback-alert"
      class="gl-mt-4"
      @dismiss="dismissFeedbackAlert"
    >
      <gl-sprintf :message="$options.i18n.feedbackAlertMessage">
        <template #link="{ content }">
          <gl-link :href="$options.feedbackIssue" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <header class="gl-my-5 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid">
      <h4>
        {{ s__('SecurityConfiguration|SAST Configuration') }}
      </h4>
      <p>
        <gl-sprintf :message="$options.i18n.helpText">
          <template #link="{ content }">
            <gl-link :href="sastDocumentationPath" target="_blank" v-text="content" />
          </template>
        </gl-sprintf>
      </p>
    </header>

    <gl-loading-icon v-if="$apollo.loading" size="lg" />

    <gl-alert
      v-else-if="hasLoadingError"
      variant="danger"
      :dismissible="false"
      data-testid="error-alert"
      >{{ $options.i18n.loadingErrorText }}</gl-alert
    >

    <configuration-form v-else :sast-ci-configuration="sastCiConfiguration" />
  </article>
</template>
