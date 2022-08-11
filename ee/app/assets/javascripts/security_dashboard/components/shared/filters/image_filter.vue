<script>
import createFlash from '~/flash';
import getVulnerabilityImagesQuery from 'ee/security_dashboard/graphql/queries/vulnerability_images.query.graphql';
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
      query: getVulnerabilityImagesQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
        };
      },
      update: (data) =>
        data.project?.vulnerabilityImages?.nodes.map((c) => ({
          id: c.name,
          name: c.name,
        })) || [],
      error() {
        createFlash({
          message: IMAGE_FILTER_ERROR,
        });
      },
    },
  },
  inject: ['projectFullPath'],
  data() {
    return {
      isLoading: 0,
      images: [],
    };
  },
  computed: {
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
