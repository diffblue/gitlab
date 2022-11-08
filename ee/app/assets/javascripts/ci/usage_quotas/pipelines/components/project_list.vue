<script>
import { GlTableLite, GlKeysetPagination, GlLink, GlSprintf } from '@gitlab/ui';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import {
  PROJECTS_TABLE_FIELDS,
  LABEL_CI_MINUTES_DISABLED,
  LABEL_NO_PROJECTS,
  USAGE_QUOTAS_HELP_LINK,
} from '../constants';

export default {
  name: 'ProjectCIMinutesList',
  components: { ProjectAvatar, GlTableLite, GlKeysetPagination, GlLink, GlSprintf },
  inject: ['pageSize', 'ciMinutesAnyProjectEnabled'],
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
  },
  PROJECTS_TABLE_FIELDS,
  LABEL_CI_MINUTES_DISABLED,
  LABEL_NO_PROJECTS,
  USAGE_QUOTAS_HELP_LINK,
};
</script>
<template>
  <section class="pipelines-project-list">
    <p v-if="!projects.length" class="gl-text-center">{{ $options.LABEL_NO_PROJECTS }}</p>
    <p v-else-if="!ciMinutesAnyProjectEnabled" class="gl-text-center">
      <gl-sprintf :message="$options.LABEL_CI_MINUTES_DISABLED">
        <template #link="{ content }">
          <gl-link class="gl-display-inline-block" :href="$options.USAGE_QUOTAS_HELP_LINK">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
    <gl-table-lite v-else :items="projects" :fields="$options.PROJECTS_TABLE_FIELDS">
      <template #cell(project)="{ item }">
        <div class="gl-display-flex gl-align-items-center">
          <project-avatar
            :project-id="item.project.id"
            :project-name="item.project.nameWithNamespace"
            :project-avatar-url="item.project.avatarUrl"
            :size="32"
            :alt="item.project.nameWithNamespace"
            class="gl-mr-3"
          />
          <gl-link
            :href="item.project.webUrl"
            class="gl-font-weight-bold"
            data-testid="pipelines-quota-tab-project-name"
            >{{ item.project.nameWithNamespace }}</gl-link
          >
        </div>
      </template>
      <template #cell(minutes)="{ item }">
        {{ item.ci_minutes }}
      </template>
    </gl-table-lite>
    <div class="gl-display-flex gl-justify-content-center gl-mt-5">
      <gl-keyset-pagination v-if="showPagination" v-bind="pageInfo" @prev="onPrev" @next="onNext" />
    </div>
  </section>
</template>
