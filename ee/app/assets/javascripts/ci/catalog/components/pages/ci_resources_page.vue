<script>
import { mockCatalogList } from '../../constants';
import CatalogHeader from '../list/catalog_header.vue';
import CiResourcesList from '../list/ci_resources_list.vue';

export default {
  components: {
    CatalogHeader,
    CiResourcesList,
  },
  mockCatalogList,
};
</script>
<template>
  <div>
    <catalog-header />
    <ci-resources-list :components="$options.mockCatalogList" />
  </div>
</template>
