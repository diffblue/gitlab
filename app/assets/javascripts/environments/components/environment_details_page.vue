<script>
import {
  GlTableLite,
  GlAvatarLink,
  GlAvatar,
  GlLink,
  GlTooltipDirective,
  GlTruncate,
  GlBadge,
  GlLoadingIcon,
} from '@gitlab/ui';
import Commit from '~/vue_shared/components/commit.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { __ } from '~/locale';
import environmentDetailsQuery from '../graphql/queries/environment_details.query.graphql';
import { convertToDeploymentTableRow } from '../helpers/deployment_data_transformation_helper';
import DeploymentStatusBadge from './deployment_status_badge.vue';

const ENVIRONMENT_DETAILS_PAGE_SIZE = 20;

export default {
  components: {
    GlLoadingIcon,
    GlBadge,
    DeploymentStatusBadge,
    TimeAgoTooltip,
    GlTableLite,
    GlAvatarLink,
    GlAvatar,
    GlLink,
    GlTruncate,
    Commit,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
    environmentName: {
      type: String,
      required: true,
    },
  },
  apollo: {
    project: {
      query: environmentDetailsQuery,
      variables() {
        return {
          projectFullPath: this.projectFullPath,
          environmentName: this.environmentName,
          pageSize: ENVIRONMENT_DETAILS_PAGE_SIZE,
        };
      },
    },
  },
  data() {
    return {
      project: {
        loading: true,
      },
      loading: 0,
      tableFields: [
        {
          key: 'status',
          label: __('Status'),
          columnClass: 'gl-w-10p',
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'id',
          label: __('ID'),
          columnClass: 'gl-w-5p',
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'triggerer',
          label: __('Triggerer'),
          columnClass: 'gl-w-10p',
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'commit',
          label: __('Commit'),
          columnClass: 'gl-w-20p',
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'job',
          label: __('Job'),
          columnClass: 'gl-w-20p',
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'created',
          label: __('Created'),
          columnClass: 'gl-w-10p',
          tdClass: 'gl-vertical-align-middle! gl-white-space-nowrap',
        },
        {
          key: 'deployed',
          label: __('Deployed'),
          columnClass: 'gl-w-10p',
          tdClass: 'gl-vertical-align-middle! gl-white-space-nowrap',
        },
      ],
    };
  },
  computed: {
    deployments() {
      return (
        this.project.environments?.nodes[0]?.deployments.nodes.map(convertToDeploymentTableRow) ||
        []
      );
    },
    isLoading() {
      return this.$apollo.queries.project.loading;
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" class="mt-3" />
    <gl-table-lite v-else :items="deployments" :fields="tableFields" fixed stacked="lg">
      <template #table-colgroup="{ fields }">
        <col v-for="field in fields" :key="field.key" :class="field.columnClass" />
      </template>
      <template #cell(status)="{ item }">
        <div>
          <deployment-status-badge :status="item.status" />
        </div>
      </template>
      <template #cell(id)="{ item }">
        <strong>{{ item.id }}</strong>
      </template>
      <template #cell(triggerer)="{ item }">
        <gl-avatar-link :href="item.triggerer.webUrl">
          <gl-avatar
            v-gl-tooltip
            :title="item.triggerer.name"
            :src="item.triggerer.avatarUrl"
            :size="24"
          />
        </gl-avatar-link>
      </template>
      <template #cell(commit)="{ item }">
        <commit v-bind="item.commit" />
      </template>
      <template #cell(job)="{ item }">
        <gl-link v-if="item.job" :href="item.job.webPath">
          <gl-truncate :text="item.job.label" />
        </gl-link>
        <gl-badge v-else variant="info">{{ __('API') }}</gl-badge>
      </template>
      <template #cell(created)="{ item }">
        <time-ago-tooltip :time="item.created" />
      </template>
      <template #cell(deployed)="{ item }">
        <time-ago-tooltip :time="item.deployed" />
      </template>
    </gl-table-lite>
  </div>
</template>
