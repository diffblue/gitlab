<script>
import { GlLink, GlTruncate, GlCollapsibleListbox, GlAvatar } from '@gitlab/ui';
import { debounce } from 'lodash';
import { s__, sprintf } from '~/locale';
import { getBaseURL, joinPaths } from '~/lib/utils/url_utility';
import { filterBySearchTerm } from '~/analytics/shared/utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { extractGroupNamespace } from 'ee/dependencies/store/utils';
import getProjects from '../graphql/projects.query.graphql';

const mapItemToListboxFormat = (item) => ({ ...item, value: item.id, text: item.name });

export default {
  name: 'DependencyProjectCount',
  components: {
    GlLink,
    GlTruncate,
    GlCollapsibleListbox,
    GlAvatar,
  },
  inject: ['endpoint'],
  props: {
    project: {
      type: Object,
      required: true,
    },
    projectCount: {
      type: Number,
      required: true,
    },
    componentId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      projects: [],
      searchTerm: '',
    };
  },
  computed: {
    projectPath() {
      const projectAbsolutePath = joinPaths(getBaseURL(), this.project.fullPath);

      return this.hasMultipleProjects ? '' : projectAbsolutePath;
    },
    projectText() {
      return this.hasMultipleProjects
        ? sprintf(s__('Dependencies|%{projectCount} projects'), {
            projectCount: Number.isNaN(this.projectCount) ? 0 : this.projectCount,
          })
        : this.project.name;
    },
    hasMultipleProjects() {
      return this.projectCount > 1;
    },
    availableProjects() {
      return filterBySearchTerm(this.projects, this.searchTerm);
    },
  },
  methods: {
    search: debounce(function debouncedSearch(searchTerm) {
      this.searchTerm = searchTerm;
      this.fetchData();
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    onHide() {
      this.searchTerm = '';
    },
    onShown() {
      this.fetchData();
    },
    async fetchData() {
      this.loading = true;

      const response = await this.$apollo.query({
        query: getProjects,
        variables: {
          groupFullPath: this.groupNamespace(),
          search: this.searchTerm,
          first: 50,
          includeSubgroups: true,
          sbomComponentId: this.componentId,
        },
      });

      const { nodes } = response.data.group.projects;

      this.loading = false;
      this.projects = nodes.map(mapItemToListboxFormat);
    },
    getEntityId(project) {
      return getIdFromGraphQLId(project.id);
    },
    setSearchTerm(val) {
      this.searchTerm = val;
    },
    getUrl(project) {
      return joinPaths(gon.relative_url_root || '', '/', project.fullPath, '-/dependencies');
    },
    groupNamespace() {
      return extractGroupNamespace(this.endpoint);
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <span>
    <gl-collapsible-listbox
      v-if="hasMultipleProjects"
      :header-text="projectText"
      :items="availableProjects"
      :searching="loading"
      searchable
      @hidden="onHide"
      @search="search"
      @shown="onShown"
    >
      <template #toggle>
        <span class="gl-md-white-space-nowrap gl-text-blue-500">
          <gl-truncate
            class="gl-display-none gl-md-display-inline-flex"
            position="start"
            :text="projectText"
            with-tooltip
          />
        </span>
      </template>
      <template #list-item="{ item }">
        <div class="gl-display-flex">
          <gl-link :href="getUrl(item)" class="gl-hover-text-decoration-none">
            <gl-avatar
              class="gl-mr-2 gl-vertical-align-middle"
              :alt="item.name"
              :size="16"
              :entity-id="getEntityId(item)"
              :entity-name="item.name"
              :src="item.avatarUrl"
              :shape="$options.AVATAR_SHAPE_OPTION_RECT"
            />
            <gl-truncate position="start" :text="item.name" with-tooltip />
          </gl-link>
        </div>
      </template>
    </gl-collapsible-listbox>
    <gl-link v-else class="gl-md-white-space-nowrap" :href="projectPath">
      <gl-truncate
        class="gl-display-none gl-md-display-inline-flex"
        position="start"
        :text="projectText"
        with-tooltip
      />
    </gl-link>
  </span>
</template>
