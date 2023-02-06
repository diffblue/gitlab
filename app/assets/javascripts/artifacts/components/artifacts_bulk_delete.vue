<script>
import { GlButton, GlModalDirective, GlModal, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/flash';
import getJobArtifactsQuery from '../graphql/queries/get_job_artifacts.query.graphql';
import bulkDestroyJobArtifactsMutation from '../graphql/mutations/bulk_destroy_job_artifacts.mutation.graphql';
import { removeArtifactFromStore } from '../graphql/cache_update';
import {
  I18N_BULK_DELETE_BANNER,
  I18N_BULK_DELETE_CLEAR_SELECTION,
  I18N_BULK_DELETE_DELETE_SELECTED,
  I18N_BULK_DELETE_MODAL_TITLE,
  I18N_BULK_DELETE_BODY,
  I18N_BULK_DELETE_ACTION,
  I18N_BULK_DELETE_CONFIRMATION_TOAST,
  I18N_BULK_DELETE_PARTIAL_ERROR,
  I18N_BULK_DELETE_ERROR,
  I18N_MODAL_CANCEL,
  BULK_DELETE_MODAL_ID,
} from '../constants';

export default {
  name: 'ArtifactsBulkDelete',
  components: {
    GlButton,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    selectedArtifacts: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isDeleting: false,
    };
  },
  computed: {
    checkedCount() {
      return this.selectedArtifacts.length || 0;
    },
    modalActionPrimary() {
      return {
        text: I18N_BULK_DELETE_ACTION(this.checkedCount),
        attributes: {
          loading: this.isDeleting,
          variant: 'danger',
        },
      };
    },
    modalActionCancel() {
      return {
        text: I18N_MODAL_CANCEL,
        attributes: {
          loading: this.isDeleting,
        },
      };
    },
  },
  methods: {
    onClearChecked() {
      this.$emit('clearSelectedArtifacts');
    },
    async onConfirmDelete(e) {
      this.isDeleting = true;
      e.preventDefault(); // don't close modal until deletion is complete
      try {
        await this.$apollo.mutate({
          mutation: bulkDestroyJobArtifactsMutation,
          variables: {
            input: {
              ids: this.selectedArtifacts,
            },
          },
          update: (store, { data }) => {
            const { errors, deletedCount, deletedIds } = data.bulkDestroyJobArtifacts;
            if (errors?.length) {
              createAlert({
                message: I18N_BULK_DELETE_PARTIAL_ERROR,
                captureError: true,
                error: new Error(errors.join(' ')),
              });
            }
            if (deletedIds?.length) {
              this.$toast.show(I18N_BULK_DELETE_CONFIRMATION_TOAST(deletedCount));

              // Remove deleted artifacts from the cache
              deletedIds.forEach((id) => {
                removeArtifactFromStore(store, id, getJobArtifactsQuery, this.queryVariables);
              });
              store.gc();
            }
          },
        });
      } catch (error) {
        this.onError(error);
      } finally {
        this.isDeleting = false;
        this.$refs.modal.hide();
      }
    },
    onError(error) {
      createAlert({
        message: I18N_BULK_DELETE_ERROR,
        captureError: true,
        error,
      });
    },
  },
  i18n: {
    banner: I18N_BULK_DELETE_BANNER,
    clearSelection: I18N_BULK_DELETE_CLEAR_SELECTION,
    deleteSelected: I18N_BULK_DELETE_DELETE_SELECTED,
    modalTitle: I18N_BULK_DELETE_MODAL_TITLE,
    modalBody: I18N_BULK_DELETE_BODY,
  },
  BULK_DELETE_MODAL_ID,
};
</script>
<template>
  <div class="gl-my-4 gl-p-4 gl-border-1 gl-border-solid gl-border-gray-100">
    <div class="gl-display-flex gl-align-items-center">
      <div>
        <gl-sprintf :message="$options.i18n.banner(checkedCount)">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </div>
      <div class="gl-ml-auto">
        <gl-button variant="default" @click="onClearChecked">
          {{ $options.i18n.clearSelection }}
        </gl-button>
        <gl-button v-gl-modal="$options.BULK_DELETE_MODAL_ID" variant="danger">
          {{ $options.i18n.deleteSelected }}
        </gl-button>
      </div>
    </div>
    <gl-modal
      ref="modal"
      size="sm"
      :modal-id="$options.BULK_DELETE_MODAL_ID"
      :title="$options.i18n.modalTitle(checkedCount)"
      :action-primary="modalActionPrimary"
      :action-cancel="modalActionCancel"
      @primary="onConfirmDelete"
    >
      <gl-sprintf :message="$options.i18n.modalBody(checkedCount)" />
    </gl-modal>
  </div>
</template>
