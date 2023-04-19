<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import CatalogHeader from '../list/catalog_header.vue';
import CiResourcesList from '../list/ci_resources_list.vue';
import getCiCatalogResources from '../../graphql/queries/get_ci_catalog_resources.query.graphql';
import { ciCatalogResourcesItemsCount } from '../../graphql/settings';
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
      currentPage: 1,
      totalCount: 0,
      pageInfo: {},
    };
  },
  apollo: {
    catalogResources: {
      query: getCiCatalogResources,
      variables() {
        return {
          fullPath: this.projectFullPath,
          first: ciCatalogResourcesItemsCount,
        };
      },
      update(data) {
        return data?.ciCatalogResources?.nodes || [];
      },
      result({ data }) {
        const { pageInfo } = data?.ciCatalogResources || {};
        this.pageInfo = pageInfo;
        this.totalCount = data?.ciCatalogResources?.count || 0;
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
    async handlePrevPage() {
      try {
        await this.$apollo.queries.catalogResources.fetchMore({
          variables: {
            before: this.pageInfo.startCursor,
            last: ciCatalogResourcesItemsCount,
            first: null,
          },
        });

        this.currentPage -= 1;
      } catch (e) {
        createAlert({ message: e?.message || this.$options.i18n.fetchError, variant: 'danger' });
      }
    },
    async handleNextPage() {
      try {
        await this.$apollo.queries.catalogResources.fetchMore({
          variables: {
            after: this.pageInfo.endCursor,
          },
        });

        this.currentPage += 1;
      } catch (e) {
        createAlert({ message: e?.message || this.$options.i18n.fetchError, variant: 'danger' });
      }
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
      :current-page="currentPage"
      :page-info="pageInfo"
      :prev-text="__('Prev')"
      :next-text="__('Next')"
      :resources="catalogResources"
      :total-count="totalCount"
      @onPrevPage="handlePrevPage"
      @onNextPage="handleNextPage"
    />
  </div>
</template>
