<script>
import { GlLoadingIcon, GlLink, GlKeysetPagination } from '@gitlab/ui';
import CorpusTable from 'ee/security_configuration/corpus_management/components/corpus_table.vue';
import CorpusUpload from 'ee/security_configuration/corpus_management/components/corpus_upload.vue';
import { s__, __ } from '~/locale';
import getCorpusesQuery from '../graphql/queries/get_corpuses.query.graphql';

export default {
  components: {
    GlLoadingIcon,
    GlLink,
    GlKeysetPagination,
    CorpusTable,
    CorpusUpload,
  },
  apollo: {
    states: {
      query: getCorpusesQuery,
      variables() {
        return this.queryVariables;
      },
      update: (data) => {
        const { pageInfo } = data.project.corpuses;
        return {
          ...data,
          pageInfo,
        };
      },
      error() {
        this.states = null;
      },
    },
  },
  inject: ['projectFullPath', 'corpusHelpPath'],
  data() {
    return {
      pagination: {
        firstPageSize: this.$options.pageSize,
        lastPageSize: null,
      },
    };
  },
  pageSize: 10,
  i18n: {
    header: s__('CorpusManagement|Fuzz testing corpus management'),
    subHeader: s__(
      'CorpusManagement|Corpus are used in fuzz testing as mutation source to Improve future testing.',
    ),
    learnMore: __('Learn More'),
    previousPage: __('Prev'),
    nextPage: __('Next'),
  },
  computed: {
    corpuses() {
      return this.states?.project.corpuses.nodes || [];
    },
    pageInfo() {
      return this.states?.pageInfo || {};
    },
    isLoading() {
      return this.$apollo.loading;
    },
    queryVariables() {
      return {
        projectPath: this.projectFullPath,
        ...this.pagination,
      };
    },
    hasPagination() {
      return Boolean(this.states) && (this.pageInfo.hasPreviousPage || this.pageInfo.hasNextPage);
    },
  },
  methods: {
    fetchCorpuses() {
      this.pagination = {
        afterCursor: null,
        beforeCursor: null,
        firstPageSize: this.$options.pageSize,
      };
      this.$apollo.queries.states.refetch();
    },
    nextPage() {
      this.pagination = {
        firstPageSize: this.$options.pageSize,
        lastPageSize: null,
        afterCursor: this.states.pageInfo.endCursor,
      };
    },
    prevPage() {
      this.pagination = {
        firstPageSize: null,
        lastPageSize: this.$options.pageSize,
        beforeCursor: this.states.pageInfo.startCursor,
      };
    },
  },
};
</script>

<template>
  <div>
    <header>
      <h4 class="gl-my-5">
        {{ this.$options.i18n.header }}
      </h4>
      <p>
        {{ this.$options.i18n.subHeader }}
        <gl-link :href="corpusHelpPath">{{ this.$options.i18n.learnMore }}</gl-link>
      </p>
    </header>

    <corpus-upload @corpus-added="fetchCorpuses" />

    <gl-loading-icon v-if="isLoading" size="lg" class="gl-py-13" />
    <template v-else>
      <corpus-table :corpuses="corpuses" />
    </template>

    <div v-if="hasPagination" class="gl-display-flex gl-justify-content-center gl-mt-5">
      <gl-keyset-pagination
        v-bind="pageInfo"
        :prev-text="$options.i18n.previousPage"
        :next-text="$options.i18n.nextPage"
        @prev="prevPage"
        @next="nextPage"
      />
    </div>
  </div>
</template>
