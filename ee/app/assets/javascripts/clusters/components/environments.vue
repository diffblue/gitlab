<script>
import {
  GlBadge,
  GlTable,
  GlEmptyState,
  GlLoadingIcon,
  GlIcon,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { __ } from '~/locale';
import DeploymentInstance from '~/vue_shared/components/deployment_instance.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlBadge,
    GlEmptyState,
    GlTable,
    GlIcon,
    TimeAgo,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    DeploymentInstance,
  },
  props: {
    isFetching: {
      type: Boolean,
      required: true,
    },
    environments: {
      type: Array,
      required: true,
    },
    environmentsHelpPath: {
      type: String,
      required: true,
    },
    clustersHelpPath: {
      type: String,
      required: true,
    },
    deployBoardsHelpPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    isEmpty() {
      return !this.isFetching && this.environments.length === 0;
    },
    podsInUseCount() {
      let podsInUse = 0;

      this.environments.forEach((environment) => {
        if (this.hasInstances(environment.rolloutStatus)) {
          podsInUse += environment.rolloutStatus.instances.length;
        }
      });

      return podsInUse;
    },
  },
  created() {
    this.$options.fields = [
      { key: 'project', label: __('Project'), class: 'pl-md-0 pr-md-5 text-nowrap' },
      { key: 'name', label: __('Environment'), class: 'pl-md-0 pr-md-5' },
      { key: 'lastDeployment', label: __('Job'), class: 'pl-md-0 pr-md-5 text-nowrap' },
      { key: 'rolloutStatus', label: __('Pods in use'), class: 'pl-md-0 pr-md-5' },
      {
        key: 'updatedAt',
        label: __('Last updated'),
        class: 'pl-md-0 pr-md-0 text-md-right text-nowrap',
      },
    ];
  },
  methods: {
    hasInstances: (rolloutStatus) => rolloutStatus.instances && rolloutStatus.instances.length,
    isLoadingRollout: (rolloutStatus) => rolloutStatus.status === 'loading',
  },
};
</script>

<template>
  <div>
    <gl-empty-state
      v-if="isEmpty"
      :title="__('No deployments found')"
      :primary-button-link="clustersHelpPath"
      :primary-button-text="__('Learn more about deploying to a cluster')"
    >
      <template #description>
        <div>
          <gl-sprintf
            :message="
              __(
                'Ensure your %{linkStart}environment is part of the deploy stage%{linkEnd} of your CI pipeline to track deployments to your cluster.',
              )
            "
          >
            <template #link="{ content }">
              <gl-link :href="environmentsHelpPath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </div>
      </template>
    </gl-empty-state>

    <gl-table
      v-if="!isFetching && !isEmpty"
      :fields="$options.fields"
      :items="environments"
      head-variant="white"
      stacked="md"
    >
      <!-- column: Project -->
      <template #cell(project)="data">
        <a :href="`/${data.value.path_with_namespace}`">{{ data.value.name }}</a>
      </template>

      <!-- column: Name -->
      <template #cell(name)="row">
        <a :href="`${row.item.environmentPath}`">{{ row.item.name }}</a>
      </template>

      <!-- column: Job -->
      <template #cell(lastDeployment)="data"> {{ __('deploy') }} #{{ data.value.id }} </template>

      <!-- column: Pods in use -->
      <template #head(rolloutStatus)="data">
        {{ data.label }} <gl-badge>{{ podsInUseCount }}</gl-badge>
      </template>

      <template #cell(rolloutStatus)="row">
        <!-- Loading Rollout -->
        <gl-loading-icon
          v-if="isLoadingRollout(row.item.rolloutStatus)"
          size="sm"
          class="d-inline-flex mt-1"
        />

        <!-- Rollout Instances -->
        <div
          v-else-if="hasInstances(row.item.rolloutStatus)"
          class="d-flex flex-wrap flex-row justify-content-end justify-content-md-start"
        >
          <template v-for="(instance, i) in row.item.rolloutStatus.instances">
            <deployment-instance
              :key="i"
              :status="instance.status"
              :tooltip-text="instance.tooltip"
              :pod-name="instance.pod_name"
              :stable="instance.stable"
            />
          </template>
        </div>

        <!-- Empty state -->
        <div v-else class="deployments-empty d-flex">
          <gl-icon name="warning" class="gl-text-orange-500 mr-2 align-self-center flex-shrink-0" />
          <span>
            <gl-sprintf
              :message="
                __(
                  'Deploy progress not found. To see pods, ensure your environment matches %{linkStart}deploy board criteria%{linkEnd}.',
                )
              "
            >
              <template #link="{ content }">
                <gl-link :href="deployBoardsHelpPath">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </span>
        </div>
      </template>

      <!-- column: Last updated -->
      <template #cell(updatedAt)="data">
        <time-ago :time="data.value" />
      </template>
    </gl-table>

    <gl-loading-icon v-if="isFetching" size="lg" class="mt-3" />
  </div>
</template>
