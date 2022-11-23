<script>
import {
  GlTableLite,
  GlAvatarLink,
  GlAvatar,
  GlLink,
  GlTooltipDirective,
  GlTruncate,
  GlBadge,
} from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import Commit from '~/vue_shared/components/commit.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { __ } from '~/locale';
import environmentDetailsQuery from '../graphql/queries/environment_details.query.graphql';
import DeploymentStatusBadge from './deployment_status_badge.vue';

const convertToDeploymentRow = (deploymentNode) => {
  return {
    status: deploymentNode.status.toLowerCase(),
    id: deploymentNode.iid,
    triggerer: deploymentNode.triggerer,
    commit: {
      ...deploymentNode.commit,
      shaLabel: deploymentNode.commit.sha.substring(0, 8),
      isTag: deploymentNode.tag,
      commitRef: {
        name: deploymentNode.ref,
        // ref_url: '#',
      },
      sAuthor: deploymentNode.commit.author && {
        username: deploymentNode.commit.author.name,
        path: deploymentNode.commit.author.webUrl,
        avatar_url: deploymentNode.commit.author.avatarUrl,
      },
    },
    job: deploymentNode.job && {
      ...deploymentNode.job,
      label: `${deploymentNode.job.name} (#${getIdFromGraphQLId(deploymentNode.job.id)})`,
    },
    created: deploymentNode.createdAt,
    deployed: deploymentNode.finishedAt,
  };
};

export default {
  components: {
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
      fields: [
        {
          key: 'status',
          label: __('Status'),
          // thClass: 'w-60p',
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'id',
          label: __('ID'),
          // thClass: 'w-15p',
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'triggerer',
          label: __('Triggerer'),
          // thClass: 'w-15p',
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'commit',
          label: __('Commit'),
          // thClass: 'gl-w-5p',
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'job',
          label: __('Job'),
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'created',
          label: __('Created'),
          tdClass: 'gl-vertical-align-middle!',
        },
        {
          key: 'deployed',
          label: __('Deployed'),
          tdClass: 'gl-vertical-align-middle!',
        },
      ],
    };
  },
  computed: {
    deployments() {
      return this.project.loading
        ? []
        : this.project.environments.nodes[0].deployments.nodes.map(convertToDeploymentRow);
    },
  },
};
</script>
<template>
  <div>
    <div v-if="project.loading">{{ __('The query is running') }}</div>
    <gl-table-lite :items="deployments" :fields="fields" stacked="lg">
      <template #cell(status)="{ item }">
        <deployment-status-badge :status="item.status" />
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
        <div class="gl-display-flex gl-justify-content-end gl-lg-justify-content-start">
          <commit
            class="gl-max-w-34"
            :tag="item.commit.isTag"
            :commit-ref="item.commit.commitRef"
            :short-sha="item.commit.shaLabel"
            :commit-url="item.commit.webUrl"
            :title="item.commit.message"
            :author="item.commit.sAuthor"
          />
        </div>
        /
        <!-- <div>
          <div>
            <gl-icon name="commit" />
            <gl-link :href="item.commit.webUrl">{{ item.commit.shaLabel }}</gl-link>
          </div>
          <div
            class="gl-display-flex gl-align-items-center gl-gap-3 gl-justify-content-end gl-lg-justify-content-start"
          >
            <gl-avatar-link v-if="!!item.commit.author" :href="item.commit.author.webUrl">
              <gl-avatar
                v-gl-tooltip
                :title="item.commit.author.name"
                :src="item.commit.author.avatarUrl"
                :size="24"
              />
            </gl-avatar-link>
            <gl-link :href="item.commit.webUrl" class="gl-display-inline-block gl-max-w-34">
              <gl-truncate :text="item.commit.message"
            /></gl-link>
          </div>
        </div> -->
      </template>
      <template #cell(job)="{ item }">
        <gl-link
          v-if="item.job"
          :href="item.job.webPath"
          class="gl-display-inline-block gl-max-w-34"
        >
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
