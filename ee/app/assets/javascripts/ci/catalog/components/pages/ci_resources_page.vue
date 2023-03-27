<script>
import { mockCatalogList } from '../../constants';
import CatalogHeader from '../list/catalog_header.vue';
import CiResourcesList from '../list/ci_resources_list.vue';
import EmptyState from '../list/empty_state.vue';

export default {
  components: {
    CatalogHeader,
    CiResourcesList,
    EmptyState,
  },
  mockCatalogList,
};
</script>
<template>
  <div>
    <catalog-header />
    <ci-resources-list :components="$options.mockCatalogList" />
    <empty-state />
  </div>
</template>
