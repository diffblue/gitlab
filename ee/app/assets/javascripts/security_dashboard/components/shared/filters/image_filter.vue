<script>
import { createAlert } from '~/flash';
import agentImagesQuery from 'ee/security_dashboard/graphql/queries/agent_images.query.graphql';
import projectImagesQuery from 'ee/security_dashboard/graphql/queries/project_images.query.graphql';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';
import { IMAGE_FILTER_ERROR } from './constants';
import SimpleFilter from './simple_filter.vue';
import FilterBody from './filter_body.vue';
import FilterItem from './filter_item.vue';

export default {
  components: { FilterBody, FilterItem },
  extends: SimpleFilter,
  apollo: {
    images: {
      loadingKey: 'isLoading',
      query() {
        return this.isAgentDashboard ? agentImagesQuery : projectImagesQuery;
      },
      variables() {
        return {
          agentName: this.agentName,
          projectPath: this.projectFullPath || this.fullPath,
        };
      },
      update(data) {
        const vulnerabilityImages = this.isAgentDashboard
          ? data.project?.clusterAgent?.vulnerabilityImages
          : data.project?.vulnerabilityImages;

        return (
          vulnerabilityImages?.nodes.map((c) => ({
            id: c.name,
            name: c.name,
          })) || []
        );
      },
      error() {
        createAlert({
          message: IMAGE_FILTER_ERROR,
        });
      },
    },
  },
  inject: {
    agentName: { default: '' },
    dashboardType: { default: DASHBOARD_TYPES.PROJECT },
    fullPath: { default: '' },
    projectFullPath: { default: '' },
  },
  data() {
    return {
      isLoading: 0,
      images: [],
    };
  },
  computed: {
    isAgentDashboard() {
      return this.dashboardType === DASHBOARD_TYPES.PROJECT && Boolean(this.agentName);
    },
    filterObject() {
      // This is passed to the vulnerability list's GraphQL query as a variable.
      return { image: this.selectedOptions.map((x) => x.id) };
    },
    // this computed property overrides the property in the SimpleFilter component
    options() {
      return this.images;
    },
  },
  watch: {
    options() {
      this.processQuerystringIds();
    },
  },
};
</script>

<template>
  <filter-body
    :name="filter.name"
    :selected-options="selectedOptionsOrAll"
    :loading="Boolean(isLoading)"
  >
    <filter-item
      :is-checked="isNoOptionsSelected"
      :text="filter.allOption.name"
      @click="deselectAllOptions"
    />
    <filter-item
      v-for="option in images"
      :key="option.id"
      :is-checked="isSelected(option)"
      :text="option.id"
      truncate
      @click="toggleOption(option)"
    />
  </filter-body>
</template>
