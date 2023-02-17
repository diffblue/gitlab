<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
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
    GlButton,
    GlModal,
    CorpusUploadForm,
  },
  directives: {
    GlModalDirective,
  },
  i18n: {
    newUpload: s__('CorpusManagement|New upload'),
    newCorpus: s__('CorpusManagement|New corpus'),
  },
  inject: ['projectFullPath', 'canUploadCorpus'],
  apollo: {
    uploadState: {
      query: getUploadState,
    },
  },
  data() {
    return {
      uploadState: {},
    };
  },
  modal: {
    actionCancel: {
      text: __('Cancel'),
    },
    modalId: 'corpus-upload-modal',
  },
  computed: {
    queryVariables() {
      return {
        projectPath: this.projectFullPath,
      };
    },
    isUploaded() {
      return Boolean(this.uploadState?.uploadedPackageId);
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
            packageId: this.uploadState?.uploadedPackageId,
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
  <div>
    <gl-button
      v-if="canUploadCorpus"
      v-gl-modal-directive="$options.modal.modalId"
      data-testid="new-corpus"
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
        :states="uploadState"
        @beginFileUpload="beginFileUpload"
        @resetCorpus="resetCorpus"
      />
    </gl-modal>
  </div>
</template>
