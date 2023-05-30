<script>
import { GlAlert, GlTable, GlLoadingIcon } from '@gitlab/ui';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import {
  LIST_EXCLUSIONS_ENDPOINT,
  exclusionListFetchError,
  excludedNamespacesDescription,
} from '../constants';
import ExcludedNamespacesForm from './excluded_namespaces_form.vue';

export default {
  components: {
    GlAlert,
    GlTable,
    GlLoadingIcon,
    ExcludedNamespacesForm,
  },
  data() {
    return {
      loading: false,
      exclusions: [],
      tableFields: [
        { key: 'namespace_name', label: __('Name') },
        { key: 'namespace_id', label: __('ID') },
        'reason',
        'operations',
      ],
      fetchError: null,
    };
  },
  created() {
    this.fetchExclusions();
  },
  i18n: {
    excludedNamespacesDescription,
  },
  methods: {
    async fetchExclusions() {
      const endpoint = Api.buildUrl(LIST_EXCLUSIONS_ENDPOINT);

      this.loading = true;
      this.fetchError = null;

      try {
        const { data } = await axios.get(endpoint);
        this.exclusions = data;
      } catch {
        this.fetchError = exclusionListFetchError;
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <div>
    <p class="gl-text-secondary">
      {{ $options.i18n.excludedNamespacesDescription }}
    </p>

    <gl-alert v-if="fetchError" variant="danger" :dismissible="false" class="gl-mb-3">
      {{ fetchError }}
    </gl-alert>
    <gl-table :items="exclusions" :fields="tableFields" :busy="loading">
      <template #table-busy>
        <div class="gl-text-center gl-text-red-500 gl-my-2">
          <gl-loading-icon />
        </div>
      </template>
    </gl-table>
    <br />
    <excluded-namespaces-form @added="fetchExclusions" />
  </div>
</template>
