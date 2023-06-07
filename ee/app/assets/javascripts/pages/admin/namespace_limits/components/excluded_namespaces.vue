<script>
import { GlAlert, GlTable, GlLoadingIcon, GlButton, GlModal } from '@gitlab/ui';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import {
  LIST_EXCLUSIONS_ENDPOINT,
  DELETE_EXCLUSION_ENDPOINT,
  exclusionListFetchError,
  exclusionDeleteError,
  excludedNamespacesDescription,
  deleteModalBody,
  deleteModalTitle,
  deleteModalProps,
} from '../constants';
import ExcludedNamespacesForm from './excluded_namespaces_form.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlTable,
    GlModal,
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
      namespaceIdToBeConfirmed: null,
    };
  },
  created() {
    this.fetchExclusions();
  },
  i18n: { excludedNamespacesDescription, deleteModalTitle, deleteModalBody },
  deleteModalProps,
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
    openConfirmationModal(namespaceId) {
      this.namespaceIdToBeConfirmed = namespaceId;
      this.$refs.modal.show();
    },
    handleModalConfirmation() {
      this.deleteExclusion(this.namespaceIdToBeConfirmed);
      // reset namespaceIdToBeConfirmed to be ready for next usage
      this.namespaceIdToBeConfirmed = null;
    },
    async deleteExclusion(namespaceId) {
      const endpoint = Api.buildUrl(DELETE_EXCLUSION_ENDPOINT).replace(':id', namespaceId);

      try {
        await axios.delete(endpoint);
        this.fetchExclusions();
      } catch (error) {
        const errorMessage = error.response?.data?.message || error.message;
        this.fetchError = sprintf(exclusionDeleteError, { errorMessage });
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
      <template #cell(operations)="{ item }">
        <gl-button
          category="primary"
          variant="danger"
          @click="openConfirmationModal(item.namespace_id)"
          >{{ __('Delete') }}</gl-button
        >
      </template>
    </gl-table>
    <gl-modal
      ref="modal"
      modal-id="namespace-exclusion-modal"
      :title="$options.i18n.deleteModalTitle"
      :action-primary="$options.deleteModalProps.primaryProps"
      :action-cancel="$options.deleteModalProps.cancelProps"
      @primary="handleModalConfirmation"
    >
      {{ $options.i18n.deleteModalBody }}
    </gl-modal>
    <br />
    <excluded-namespaces-form @added="fetchExclusions" />
  </div>
</template>
