<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';

import { reloadPage, persistBaseUrl, retrieveBaseUrl } from '~/jira_connect/subscriptions/utils';
import SignInOauthButton from '../../../components/sign_in_oauth_button.vue';
import { updateInstallation, setApiBaseURL } from '../../../api';
import VersionSelectForm from './version_select_form.vue';

export default {
  name: 'SignInGitlabMultiversion',
  components: {
    GlButton,
    SignInOauthButton,
    VersionSelectForm,
  },
  data() {
    return {
      gitlabBasePath: null,
    };
  },
  computed: {
    hasSelectedVersion() {
      return this.gitlabBasePath !== null;
    },
    subtitle() {
      return this.hasSelectedVersion
        ? this.$options.i18n.signInSubtitle
        : this.$options.i18n.versionSelectSubtitle;
    },
  },
  mounted() {
    this.gitlabBasePath = retrieveBaseUrl();
    setApiBaseURL(this.gitlabBasePath);
  },
  methods: {
    resetGitlabBasePath() {
      this.gitlabBasePath = null;
      setApiBaseURL(null);
    },
    onVersionSelect(gitlabBasePath) {
      updateInstallation(gitlabBasePath)
        .then(() => {
          persistBaseUrl(gitlabBasePath);
          reloadPage();
        })
        .catch(() => {});
    },
    onSignInError() {
      this.$emit('error');
    },
  },
  i18n: {
    title: s__('JiraService|Welcome to GitLab for Jira'),
    signInSubtitle: s__('JiraService|Sign in to GitLab to link namespaces.'),
    versionSelectSubtitle: s__('JiraService|What version of GitLab are you using?'),
    changeVersionButtonText: s__('JiraService|Change GitLab version'),
  },
};
</script>

<template>
  <div>
    <div class="gl-text-center">
      <h2>{{ $options.i18n.title }}</h2>
      <p data-testid="subtitle">{{ subtitle }}</p>
    </div>

    <version-select-form v-if="!hasSelectedVersion" class="gl-mt-7" @submit="onVersionSelect" />

    <div v-else class="gl-text-center">
      <sign-in-oauth-button
        class="gl-mb-5"
        :gitlab-base-path="gitlabBasePath"
        @sign-in="$emit('sign-in-oauth', $event)"
        @error="onSignInError"
      />

      <div>
        <gl-button category="tertiary" variant="confirm" @click="resetGitlabBasePath">
          {{ $options.i18n.changeVersionButtonText }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
