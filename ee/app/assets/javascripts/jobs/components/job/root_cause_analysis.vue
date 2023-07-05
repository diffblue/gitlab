<script>
import { GlDrawer, GlEmptyState, GlSkeletonLoader, GlSprintf, GlLink, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import Markdown from '~/vue_shared/components/markdown/non_gfm_markdown.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import rootCauseMutation from './graphql/root_cause.mutation.graphql';
import rootCauseQuery from './graphql/root_cause.query.graphql';

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlLink,
    GlSprintf,
    GlDrawer,
    Markdown,
    GlSkeletonLoader,
  },
  inject: ['projectPath'],
  props: {
    isShown: {
      type: Boolean,
      required: true,
    },
    jobId: {
      type: String,
      required: false,
      default: null,
    },
    isJobLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      messages: [],
      error: null,
      isRootCauseRequested: false,
      project: {
        job: {
          aiFailureAnalysis: null,
        },
      },
    };
  },
  apollo: {
    project: {
      query: rootCauseQuery,
      variables() {
        return {
          projectFullPath: this.projectPath,
          jobId: this.jobId,
        };
      },
      pollInterval() {
        return !this.isResponseReady && this.isRootCauseRequested ? 1000 : 0;
      },
    },
  },
  computed: {
    isResponseReady() {
      return Boolean(this.message);
    },
    isRootCauseLoading() {
      return this.isRootCauseRequested && !this.isResponseReady;
    },
    message() {
      return this.project?.job?.aiFailureAnalysis;
    },
  },
  watch: {
    isJobLoading() {
      this.fetchData();
    },
  },
  methods: {
    closeDrawer() {
      this.$emit('close');
    },
    fetchData() {
      if (!this.isJobLoading && !this.isRootCauseRequested) {
        this.isRootCauseRequested = true;
        this.$apollo.mutate({
          mutation: rootCauseMutation,
          variables: {
            jobId: this.jobId,
          },
        });
      }
    },
  },
  helpPagePath: helpPagePath('user/ai_features', { anchor: 'third-party-ai-features' }),
  i18n: {
    drawerTitle: __('Root cause analysis'),
    bannerTitle: __('What is root cause analysis?'),
    actionButtonText: __('Generate root cause analysis'),
    explanationText: __(
      'Root cause analysis is a feature that analyzes your logs to determine why a job may have failed and the potential ways to fix it. To generate this analysis, we may share information in your job logs with %{linkStart}Third-Party AI providers%{linkEnd}. Before initiating this analysis, please do not include in your logs any information that could impact the security or privacy of your account.',
    ),
  },
};
</script>
<template>
  <gl-drawer :open="isShown" class="gl-z-index-9999!" @close="closeDrawer">
    <template #title>
      <h3>{{ $options.i18n.drawerTitle }}</h3>
    </template>
    <gl-empty-state v-if="!isResponseReady && !isRootCauseLoading" compact>
      <template #title>
        <h3>{{ $options.i18n.bannerTitle }}</h3>
      </template>
      <template #description>
        <p>
          <gl-sprintf :message="$options.i18n.explanationText">
            <template #link="{ content }">
              <gl-link :href="$options.helpPagePath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </template>
      <template #actions>
        <gl-button class="gl-mb-3" category="primary" variant="confirm" @click="fetchData">{{
          $options.i18n.actionButtonText
        }}</gl-button>
      </template>
    </gl-empty-state>
    <gl-skeleton-loader v-if="isRootCauseLoading" />
    <markdown v-if="isResponseReady" :markdown="message" />
  </gl-drawer>
</template>
