<script>
import { GlLoadingIcon, GlLink } from '@gitlab/ui';
import CorpusTable from 'ee/security_configuration/corpus_management/components/corpus_table.vue';
import CorpusUpload from 'ee/security_configuration/corpus_management/components/corpus_upload.vue';
import { s__, __ } from '~/locale';
import getCorpusesQuery from '../graphql/queries/get_corpuses.query.graphql';

export default {
  components: {
    GlLoadingIcon,
    GlLink,
    CorpusTable,
    CorpusUpload,
  },
  apollo: {
    states: {
      query: getCorpusesQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
        };
      },
      update: (data) => {
        return data;
      },
      error() {
        this.states = null;
      },
    },
  },
  inject: ['projectFullPath', 'corpusHelpPath'],
  i18n: {
    header: s__('CorpusManagement|Fuzz testing corpus management'),
    subHeader: s__(
      'CorpusManagement|Corpus are used in fuzz testing as mutation source to Improve future testing.',
    ),
    learnMore: __('Learn More'),
  },
  computed: {
    mockedData() {
      return this.states?.mockedPackages.data || [];
    },
    isLoading() {
      return this.$apollo.loading;
    },
    totalSize() {
      return this.states?.mockedPackages.totalSize;
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

    <gl-loading-icon v-if="isLoading" size="lg" />
    <template v-else>
      <corpus-upload :total-size="totalSize" />
      <corpus-table :corpuses="mockedData" />
    </template>
  </div>
</template>
