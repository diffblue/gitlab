<script>
import { GlAlert, GlSprintf, GlTableLite, GlKeysetPagination, GlLink } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { formatDate } from '~/lib/utils/datetime_utility';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import {
  PROJECTS_TABLE_FIELDS,
  LABEL_CI_MINUTES_DISABLED,
  SHARED_RUNNERS_DOC_LINK,
  PROJECTS_TABLE_USAGE_SINCE,
  PROJECTS_NO_SHARED_RUNNERS,
  PROJECTS_TABLE_OMITS_MESSAGE,
} from '../constants';

export default {
  name: 'ProjectCIMinutesList',
  components: { ProjectAvatar, GlAlert, GlSprintf, GlTableLite, GlKeysetPagination, GlLink },
  inject: ['pageSize', 'ciMinutesAnyProjectEnabled', 'ciMinutesLastResetDate'],
  props: {
    projects: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showPagination() {
      return Boolean(this.pageInfo?.hasPreviousPage || this.pageInfo?.hasNextPage);
    },
    projectsTableInfoMessage() {
      return sprintf(PROJECTS_TABLE_USAGE_SINCE, {
        usageSince: formatDate(this.ciMinutesLastResetDate, 'mmm dd, yyyy', true),
      });
    },
  },
  methods: {
    fetchMoreProjects(variables) {
      this.$emit('fetchMore', variables);
    },
    onPrev(before) {
      if (this.pageInfo.hasPreviousPage) {
        this.fetchMoreProjects({ before, last: this.pageSize, first: undefined });
      }
    },
    onNext(after) {
      if (this.pageInfo.hasNextPage) {
        this.fetchMoreProjects({ after, first: this.pageSize });
      }
    },
    formattedSharedRunnersDuration(sharedRunnersDuration) {
      return (sharedRunnersDuration / 60).toFixed(2);
    },
  },
  LABEL_CI_MINUTES_DISABLED,
  SHARED_RUNNERS_DOC_LINK,
  PROJECTS_TABLE_FIELDS,
  PROJECTS_NO_SHARED_RUNNERS,
  PROJECTS_TABLE_OMITS_MESSAGE,
};
</script>
<template>
  <section class="pipelines-project-list" data-testid="pipelines-quota-tab-project-table">
    <gl-alert :dismissible="false" class="gl-my-3" data-testid="project-usage-info-alert">
      {{ projectsTableInfoMessage }}
    </gl-alert>
    <gl-table-lite :items="projects" :fields="$options.PROJECTS_TABLE_FIELDS">
      <template #cell(project)="{ item: { project } }">
        <div class="gl-display-flex gl-align-items-center">
          <project-avatar
            :project-id="project.id"
            :project-name="project.nameWithNamespace"
            :project-avatar-url="project.avatarUrl"
            :size="24"
            :alt="project.nameWithNamespace"
            class="gl-mr-3"
          />
          <gl-link
            :href="project.webUrl"
            class="gl-font-weight-bold"
            data-testid="pipelines-quota-tab-project-name"
            >{{ project.nameWithNamespace }}</gl-link
          >
        </div>
      </template>
      <template #cell(shared_runners)="{ item }">
        <span data-testid="project_shared_runner_duration">{{
          formattedSharedRunnersDuration(item.sharedRunnersDuration)
        }}</span>
      </template>
      <template #cell(ci_minutes)="{ item }">
        <span data-testid="project_amount_used">{{ item.minutes }}</span>
      </template>
    </gl-table-lite>
    <p v-if="!ciMinutesAnyProjectEnabled" class="gl-text-center gl-p-5">
      <gl-sprintf :message="$options.LABEL_CI_MINUTES_DISABLED">
        <template #link="{ content }">
          <gl-link :href="$options.SHARED_RUNNERS_DOC_LINK">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <div v-else>
      <p
        v-if="!projects.length"
        class="gl-text-center gl-border-b-1 gl-border-b-solid gl-border-gray-100 gl-pb-5 gl-mb-0"
      >
        {{ $options.PROJECTS_NO_SHARED_RUNNERS }}
      </p>
      <p class="gl-text-center gl-py-5">
        {{ $options.PROJECTS_TABLE_OMITS_MESSAGE }}
      </p>
    </div>
    <div class="gl-display-flex gl-justify-content-center gl-mt-5">
      <gl-keyset-pagination v-if="showPagination" v-bind="pageInfo" @prev="onPrev" @next="onNext" />
    </div>
  </section>
</template>
