<script>
import { mockCatalogResourceList } from '../../constants';
import CatalogHeader from '../list/catalog_header.vue';
import CiResourcesList from '../list/ci_resources_list.vue';
import EmptyState from '../list/empty_state.vue';

export default {
  components: {
    CatalogHeader,
    CiResourcesList,
    EmptyState,
  },
  mockCatalogResourceList,
};
</script>
<template>
  <div>
    <catalog-header />
    <ci-resources-list :resources="$options.mockCatalogResourceList" />
    <empty-state />
  </div>
</template>
