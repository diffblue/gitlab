<script>
import { GlLoadingIcon, GlLink, GlKeysetPagination } from '@gitlab/ui';
import { fetchPolicies } from '~/lib/graphql';
import EmptyState from 'ee/security_configuration/corpus_management/components/empty_state.vue';
import CorpusTable from 'ee/security_configuration/corpus_management/components/corpus_table.vue';
import CorpusUpload from 'ee/security_configuration/corpus_management/components/corpus_upload.vue';
import CorpusUploadButton from 'ee/security_configuration/corpus_management/components/corpus_upload_button.vue';
import { s__, __ } from '~/locale';
import getCorpusesQuery from '../graphql/queries/get_corpuses.query.graphql';
import deleteCorpusMutation from '../graphql/mutations/delete_corpus.mutation.graphql';

export default {
  components: {
    EmptyState,
    GlLoadingIcon,
    GlLink,
    GlKeysetPagination,
    CorpusTable,
    CorpusUpload,
    CorpusUploadButton,
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
  inject: ['emptyStateSvgPath', 'projectFullPath', 'corpusHelpPath'],
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
      'CorpusManagement|Corpus files are used in coverage-guided fuzz testing as seed inputs to improve testing.',
    ),
    learnMore: __('Learn More'),
    previousPage: __('Prev'),
    nextPage: __('Next'),
  },
  computed: {
    corpuses() {
      return this.states?.project.corpuses.nodes || [];
    },
    hasCorpuses() {
      return this.corpuses.length > 0;
    },
    pageInfo() {
      return this.states?.pageInfo || {};
    },
    isLoading() {
      return this.$apollo.loading;
    },
    previousPageHasNodes() {
      return this.corpuses.length === 0 && this.pageInfo.hasPreviousPage;
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

      this.$apollo.queries.states.setOptions({
        fetchPolicy: fetchPolicies.NETWORK_ONLY,
        nextFetchPolicy: fetchPolicies.CACHE_FIRST,
      });
    },
    onDelete(id) {
      return this.$apollo
        .mutate({
          mutation: deleteCorpusMutation,
          variables: {
            input: {
              id,
            },
          },
        })
        .then(() => this.$apollo.queries.states.refetch())
        .then(() => {
          /**
           * this is an edge case
           * when we delete last item on the page
           * and previous page has nodes we need to
           * change page to previous, otherwise
           * we see empty state
           */
          if (this.previousPageHasNodes) {
            this.prevPage();
          }
        });
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
    <template v-if="!hasCorpuses">
      <gl-loading-icon v-if="isLoading" size="lg" class="gl-py-13" />
      <empty-state v-else>
        <template #actions>
          <corpus-upload-button @corpus-added="fetchCorpuses" />
        </template>
      </empty-state>
    </template>
    <div v-else>
      <header>
        <h4 class="gl-my-5">
          {{ $options.i18n.header }}
        </h4>
        <p>
          {{ $options.i18n.subHeader }}
          <gl-link :href="corpusHelpPath">{{ $options.i18n.learnMore }}</gl-link>
        </p>
      </header>

      <corpus-upload>
        <template #action>
          <corpus-upload-button class="gl-mr-5 gl-ml-auto" @corpus-added="fetchCorpuses" />
        </template>
      </corpus-upload>

      <gl-loading-icon v-if="isLoading" size="lg" class="gl-py-6" />
      <template v-else>
        <corpus-table :corpuses="corpuses" @delete="onDelete" />
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
  </div>
</template>
