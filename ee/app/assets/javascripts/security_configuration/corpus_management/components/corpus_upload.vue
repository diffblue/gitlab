<script>
import { GlButton, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { decimalBytes } from '~/lib/utils/unit_format';
import { s__, __ } from '~/locale';
import addCorpusMutation from '../graphql/mutations/add_corpus.mutation.graphql';
import resetCorpus from '../graphql/mutations/reset_corpus.mutation.graphql';
import uploadCorpus from '../graphql/mutations/upload_corpus.mutation.graphql';
import getUploadState from '../graphql/queries/get_upload_state.query.graphql';
import uploadError from '../graphql/mutations/upload_error.mutation.graphql';
import { I18N, MAX_FILE_SIZE } from '../constants';
import CorpusUploadForm from './corpus_upload_form.vue';

export default {
  components: {
    GlSprintf,
    GlButton,
    GlModal,
    CorpusUploadForm,
  },
  directives: {
    GlModalDirective,
  },
  i18n: {
    totalSize: s__('CorpusManagement|Total Size: %{totalSize}'),
    newUpload: s__('CorpusManagement|New upload'),
    newCorpus: s__('CorpusMnagement|New corpus'),
  },
  inject: ['projectFullPath', 'canUploadCorpus'],
  apollo: {
    states: {
      query: getUploadState,
      update(data) {
        return data;
      },
    },
  },
  modal: {
    actionCancel: {
      text: __('Cancel'),
    },
    modalId: 'corpus-upload-modal',
  },
  props: {
    totalSize: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    queryVariables() {
      return {
        projectPath: this.projectFullPath,
      };
    },
    formattedFileSize() {
      return decimalBytes(this.totalSize);
    },
    isUploaded() {
      return Boolean(this.states?.uploadState.uploadedPackageId);
    },
    variant() {
      return this.isUploaded ? 'confirm' : 'default';
    },
    actionPrimaryProps() {
      return {
        text: __('Add'),
        attributes: {
          'data-testid': 'modal-confirm',
          disabled: !this.isUploaded,
          variant: this.variant,
        },
      };
    },
  },
  methods: {
    addCorpus() {
      return this.$apollo
        .mutate({
          mutation: addCorpusMutation,
          variables: {
            name: this.$options.i18n.newCorpus,
            projectPath: this.projectFullPath,
            packageId: this.states.uploadState.uploadedPackageId,
          },
        })
        .then(() => {
          this.$emit('corpus-added');
        });
    },
    resetCorpus() {
      this.$apollo.mutate({
        mutation: resetCorpus,
        variables: { projectPath: this.projectFullPath },
      });
    },
    beginFileUpload({ name, files }) {
      if (files[0].size >= MAX_FILE_SIZE) {
        this.$apollo.mutate({
          mutation: uploadError,
          variables: { projectPath: this.projectFullPath, error: I18N.fileTooLarge },
        });
      } else {
        this.$apollo.mutate({
          mutation: uploadCorpus,
          variables: { name, projectPath: this.projectFullPath, files },
        });
      }
    },
  },
};
</script>
<template>
  <div
    class="gl-h-11 gl-bg-gray-10 gl-display-flex gl-justify-content-space-between gl-align-items-center"
  >
    <div v-if="totalSize" class="gl-ml-5">
      <gl-sprintf :message="$options.i18n.totalSize">
        <template #totalSize>
          <span class="gl-font-weight-bold">{{ formattedFileSize }}</span>
        </template>
      </gl-sprintf>
    </div>

    <gl-button
      v-if="canUploadCorpus"
      v-gl-modal-directive="$options.modal.modalId"
      data-testid="new-corpus"
      class="gl-mr-5 gl-ml-auto"
      variant="confirm"
    >
      {{ $options.i18n.newCorpus }}
    </gl-button>

    <gl-modal
      :modal-id="$options.modal.modalId"
      :title="$options.i18n.newCorpus"
      size="sm"
      :action-primary="actionPrimaryProps"
      :action-cancel="$options.modal.actionCancel"
      @primary="addCorpus"
      @canceled="resetCorpus"
    >
      <corpus-upload-form
        :states="states"
        @beginFileUpload="beginFileUpload"
        @resetCorpus="resetCorpus"
      />
    </gl-modal>
  </div>
</template>
