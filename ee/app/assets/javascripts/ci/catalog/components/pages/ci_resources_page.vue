<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import CatalogHeader from '../list/catalog_header.vue';
import CiResourcesList from '../list/ci_resources_list.vue';
import getCiCatalogResources from '../../graphql/queries/get_ci_catalog_resources.query.graphql';
import EmptyState from '../list/empty_state.vue';

export default {
  components: {
    CatalogHeader,
    CiResourcesList,
    EmptyState,
    GlLoadingIcon,
  },
  inject: ['projectFullPath'],
  data() {
    return {
      catalogResources: [],
      pageInfo: {},
    };
  },
  apollo: {
    catalogResources: {
      query: getCiCatalogResources,
      variables() {
        return {
          fullPath: this.projectFullPath,
          first: 20,
        };
      },
      update(data) {
        return data?.ciCatalogResources?.nodes || [];
      },
      result({ data }) {
        const { pageInfo } = data?.ciCatalogResources || {};
        this.pageInfo = pageInfo;
      },
      error(e) {
        createAlert({ message: e.message || this.$options.i18n.fetchError, variant: 'danger' });
      },
    },
  },
  computed: {
    hasResources() {
      return this.catalogResources.length > 0;
    },
    isLoading() {
      return this.$apollo.queries.catalogResources.loading;
    },
  },
  methods: {
    handlePrevPage() {
      this.$apollo.queries.catalogResources.fetchMore({
        variables: {
          before: this.pageInfo.startCursor,
          last: 20,
          first: null,
        },
      });
    },
    handleNextPage() {
      this.$apollo.queries.catalogResources.fetchMore({
        variables: {
          after: this.pageInfo.endCursor,
        },
      });
    },
  },
  i18n: {
    fetchError: s__('CiCatalog|There was an error fetching CI/CD Catalog resources.'),
  },
};
</script>
<template>
  <div>
    <catalog-header />
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <empty-state v-else-if="!hasResources" />
    <ci-resources-list
      v-else
      :page-info="pageInfo"
      :resources="catalogResources"
      @onPrevPage="handlePrevPage"
      @onNextPage="handleNextPage"
    />
  </div>
</template>
