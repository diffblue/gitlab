<script>
import { GlAlert, GlButton, GlLoadingIcon } from '@gitlab/ui';
import { TYPE_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { pushEECproductAddToCartEvent } from '~/google_tag_manager';
import getCiMinutesUsageProfile from 'ee/ci_minutes_usage/graphql/queries/ci_minutes.query.graphql';
import getCiMinutesUsageNamespace from '../../ci_minutes_usage/graphql/queries/ci_minutes_namespace.query.graphql';
import getNamespaceProjectsInfo from '../queries/namespace_projects_info.query.graphql';
import { getProjectMinutesUsage } from '../utils';
import { ERROR_MESSAGE, LABEL_BUY_ADDITIONAL_MINUTES } from '../constants';
import ProjectList from './project_list.vue';

export default {
  name: 'PipelineUsageApp',
  components: { GlAlert, GlButton, GlLoadingIcon, ProjectList },
  inject: [
    'namespacePath',
    'namespaceId',
    'userNamespace',
    'pageSize',
    'namespaceActualPlanName',
    'buyAdditionalMinutesPath',
    'buyAdditionalMinutesTarget',
  ],
  data() {
    return {
      error: '',
      namespace: null,
      ciMinutesUsages: null,
    };
  },
  apollo: {
    namespace: {
      query: getNamespaceProjectsInfo,
      variables() {
        return {
          fullPath: this.namespacePath,
          first: this.pageSize,
        };
      },
      error() {
        this.error = ERROR_MESSAGE;
      },
    },
    ciMinutesUsages: {
      query() {
        return this.userNamespace ? getCiMinutesUsageProfile : getCiMinutesUsageNamespace;
      },
      variables() {
        return {
          namespaceId: convertToGraphQLId(TYPE_GROUP, this.namespaceId),
        };
      },
      update(res) {
        return res?.ciMinutesUsage?.nodes;
      },
      error() {
        this.error = ERROR_MESSAGE;
      },
    },
  },
  computed: {
    projects() {
      return this.namespace?.projects?.nodes.map((project) => ({
        project,
        ci_minutes: getProjectMinutesUsage(project, this.ciMinutesUsages),
      }));
    },
    projectsPageInfo() {
      return this.namespace?.projects?.pageInfo ?? {};
    },
    shouldShowBuyAdditionalMinutes() {
      return this.buyAdditionalMinutesPath && this.buyAdditionalMinutesTarget;
    },
    isLoading() {
      return this.$apollo.queries.namespace.loading || this.$apollo.queries.ciMinutesUsages.loading;
    },
  },
  methods: {
    clearError() {
      this.error = '';
    },
    fetchMoreProjects(variables) {
      this.$apollo.queries.namespace.fetchMore({
        variables: {
          fullPath: this.namespacePath,
          ...variables,
        },
        updateQuery(previousResult, { fetchMoreResult }) {
          return fetchMoreResult;
        },
      });
    },
    trackBuyAdditionalMinutesClick() {
      pushEECproductAddToCartEvent();
    },
  },
  LABEL_BUY_ADDITIONAL_MINUTES,
};
</script>

<template>
  <div>
    <section>
      <div v-if="shouldShowBuyAdditionalMinutes" class="gl-display-flex gl-justify-content-end">
        <gl-button
          :href="buyAdditionalMinutesPath"
          :target="buyAdditionalMinutesTarget"
          :data-track-label="namespaceActualPlanName"
          data-track-action="click_buy_ci_minutes"
          data-track-property="pipeline_quota_page"
          category="primary"
          variant="confirm"
          @click="trackBuyAdditionalMinutesClick"
        >
          {{ $options.LABEL_BUY_ADDITIONAL_MINUTES }}
        </gl-button>
      </div>
    </section>
    <section class="gl-py-5">
      <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="md" />
      <gl-alert v-else-if="error" variant="danger" @dismiss="clearError">
        {{ error }}
      </gl-alert>
      <div v-else>
        <project-list
          :projects="projects"
          :page-info="projectsPageInfo"
          @fetchMore="fetchMoreProjects"
        />
      </div>
    </section>
  </div>
</template>
