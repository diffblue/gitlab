<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlButton, GlIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import { redirectTo } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

import { addProjectToSlack } from '../api';
import ProjectsDropdown from './projects_dropdown.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    ProjectsDropdown,
  },
  props: {
    projects: {
      type: Array,
      required: false,
      default: () => [],
    },
    isSignedIn: {
      type: Boolean,
      required: true,
    },
    gitlabForSlackGifPath: {
      type: String,
      required: true,
    },
    signInPath: {
      type: String,
      required: true,
    },
    slackLinkPath: {
      type: String,
      required: true,
    },
    gitlabLogoPath: {
      type: String,
      required: true,
    },
    slackLogoPath: {
      type: String,
      required: true,
    },
    docsPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedProject: null,
    };
  },
  computed: {
    hasProjects() {
      return this.projects.length > 0;
    },
  },
  methods: {
    selectProject(project) {
      this.selectedProject = project;
    },
    addToSlack() {
      addProjectToSlack(this.slackLinkPath, this.selectedProject.id)
        .then((response) => redirectTo(response.data.add_to_slack_link))
        .catch(() =>
          createFlash({
            message: __('Unable to build Slack link.'),
          }),
        );
    },
  },
};
</script>

<template>
  <div class="gitlab-slack-body gl-mx-auto gl-mt-11 gl-text-center">
    <div v-once class="gl-my-5 gl-display-flex gl-justify-content-center gl-align-items-center">
      <img :src="gitlabLogoPath" class="gl-h-11 gl-w-11" />
      <gl-icon name="arrow-right" :size="32" class="gl-mx-5 gl-text-gray-200" />
      <img :src="slackLogoPath" class="gitlab-slack-slack-logo gl-h-11 gl-w-11" />
    </div>

    <h1>{{ s__('SlackIntegration|GitLab for Slack') }}</h1>

    <div class="gl-mt-6" data-testid="gitlab-slack-content">
      <template v-if="isSignedIn">
        <template v-if="hasProjects">
          <p>
            {{ s__('SlackIntegration|Select a GitLab project to link with your Slack workspace.') }}
          </p>

          <projects-dropdown
            :projects="projects"
            :selected-project="selectedProject"
            @project-selected="selectProject"
          />

          <div class="gl-display-flex gl-justify-content-end">
            <gl-button
              category="primary"
              variant="confirm"
              class="float-right"
              :disabled="!selectedProject"
              @click="addToSlack"
            >
              {{ __('Continue') }}
            </gl-button>
          </div>
        </template>
        <template v-else>
          <p>{{ __("You don't have any projects available.") }}</p>
        </template>
      </template>

      <template v-else>
        <p>{{ s__('JiraService|Sign in to GitLab.com to get started.') }}</p>
        <gl-button category="primary" variant="confirm" :href="signInPath">{{
          __('Sign in to GitLab')
        }}</gl-button>
      </template>
    </div>

    <div class="center prepend-top-20 gl-mb-3 gl-mr-2 gl-ml-2">
      <img v-once :src="gitlabForSlackGifPath" class="gl-w-full" />
    </div>

    <div v-once class="text-center">
      <h3>{{ __('How it works') }}</h3>

      <div class="mx-auto">
        <code class="code mx-auto gl-mb-3"
          >/gitlab &lt;project-alias&gt; issue show &lt;id&gt;</code
        >
        <span>
          <gl-icon name="arrow-right" class="gl-mr-2 gl-text-gray-200" />
          Shows the issue with id <strong>&lt;id&gt;</strong>
        </span>

        <div class="gl-mt-3">
          <a v-once :href="docsPath">{{ __('More Slack commands') }}</a>
        </div>
      </div>
    </div>
  </div>
</template>
