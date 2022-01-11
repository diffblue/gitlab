<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlButton, GlIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import { redirectTo } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

import GitlabSlackService from '../services/gitlab_slack_service';

export default {
  components: {
    GlButton,
    GlIcon,
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
      selectedProjectId: this.projects && this.projects.length ? this.projects[0].id : 0,
    };
  },

  computed: {
    hasProjects() {
      return this.projects.length > 0;
    },
  },

  methods: {
    addToSlack() {
      GitlabSlackService.addToSlack(this.slackLinkPath, this.selectedProjectId)
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
    <p>{{ s__('SlackIntegration|Select a GitLab project to link with your Slack workspace.') }}</p>

    <div class="mx-auto prepend-top-20 text-center">
      <div v-if="isSignedIn && hasProjects">
        <select v-model="selectedProjectId" class="js-project-select form-control gl-mt-3 gl-mb-3">
          <option v-for="project in projects" :key="project.id" :value="project.id">
            {{ project.name }}
          </option>
        </select>

        <div class="gl-display-flex gl-justify-content-end">
          <gl-button category="primary" variant="confirm" class="float-right" @click="addToSlack">
            {{ __('Continue') }}
          </gl-button>
        </div>
      </div>

      <span v-else-if="isSignedIn && !hasProjects" class="js-no-projects">{{
        __("You don't have any projects available.")
      }}</span>

      <span v-else>
        You have to
        <a v-once :href="signInPath" class="js-gitlab-slack-sign-in-link">{{ __('log in') }}</a>
      </span>
    </div>

    <div class="center prepend-top-20 gl-mb-3 gl-mr-2 gl-ml-2">
      <img v-once :src="gitlabForSlackGifPath" class="gl-w-full" />
    </div>

    <div v-once class="text-center">
      <h3>{{ __('How it works') }}</h3>

      <div class="well gitlab-slack-well mx-auto">
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
