<script>
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
  </div>
</template>
