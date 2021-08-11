<script>
import {
  GlForm,
  GlFormInput,
  GlFormInputGroup,
  GlButton,
  GlLoadingIcon,
  GlFormGroup,
} from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { VALID_CORPUS_MIMETYPE } from '../constants';
import resetCorpus from '../graphql/mutations/reset_corpus.mutation.graphql';
import uploadCorpus from '../graphql/mutations/upload_corpus.mutation.graphql';
import getCorpusesQuery from '../graphql/queries/get_corpuses.query.graphql';

export default {
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLoadingIcon,
    GlFormInputGroup,
    GlButton,
  },
  inject: ['projectFullPath'],
  i18n: {
    corpusName: s__('CorpusManagement|Corpus name'),
    uploadButtonText: __('Choose File...'),
    uploadMessage: s__(
      'CorpusManagement|New corpus needs to be a upload in *.zip format. Maximum 10GB',
    ),
  },
  apollo: {
    states: {
      query: getCorpusesQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
        };
      },
      update(data) {
        return data;
      },
      error() {
        this.states = null;
      },
    },
  },
  data() {
    return {
      attachmentName: '',
      corpusName: '',
      files: [],
      uploadTimeout: null,
    };
  },
  computed: {
    hasAttachment() {
      return Boolean(this.attachmentName);
    },
    isShowingAttachmentName() {
      return this.hasAttachment && !this.isLoading;
    },
    isShowingAttachmentCancel() {
      return !this.isUploaded && !this.isUploading;
    },
    isUploading() {
      return this.states?.uploadState.isUploading;
    },
    isUploaded() {
      return this.states?.uploadState.progress === 100;
    },
    showUploadButton() {
      return this.hasAttachment && !this.isUploading && !this.isUploaded;
    },
    showFilePickerButton() {
      return !this.isUploaded;
    },
    progress() {
      return this.states?.uploadState.progress;
    },
    progressText() {
      return sprintf(__('Attaching File - %{progress}'), { progress: `${this.progress}%` });
    },
  },
  beforeDestroy() {
    this.resetAttachment();
    this.cancelUpload();
  },
  methods: {
    clearName() {
      this.corpusName = '';
    },
    resetAttachment() {
      this.$refs.fileUpload.value = null;
      this.attachmentName = '';
      this.files = [];
    },
    cancelUpload() {
      clearTimeout(this.uploadTimeout);
      this.$apollo.mutate({
        mutation: resetCorpus,
        variables: { name: this.corpusName, projectPath: this.projectFullPath },
      });
    },
    openFileUpload() {
      this.$refs.fileUpload.click();
    },
    beginFileUpload() {
      // const component = this;
      // Simulate incrementing file upload progress
      return this.$apollo
        .mutate({
          mutation: uploadCorpus,
          variables: { name: this.corpusName, projectPath: this.projectFullPath },
        })
        .then(({ data }) => {
          if (data.uploadCorpus < 100) {
            this.uploadTimeout = setTimeout(() => {
              this.beginFileUpload();
            }, 500);
          }
        });
    },
    onFileUploadChange(e) {
      this.attachmentName = e.target.files[0].name;
      this.files = e.target.files;
    },
  },
  VALID_CORPUS_MIMETYPE,
};
</script>
<template>
  <gl-form>
    <gl-form-group :label="$options.i18n.corpusName" label-size="sm" label-for="corpus-name">
      <gl-form-input-group>
        <gl-form-input
          id="corpus-name"
          ref="input"
          v-model="corpusName"
          data-testid="corpus-name"
        />

        <gl-button
          class="gl-absolute gl-top-2 gl-right-2 gl-z-index-3"
          variant="default"
          category="tertiary"
          size="small"
          name="clear"
          title="title"
          icon="clear"
          :aria-label="__(`Clear`)"
          @click="clearName"
        />
      </gl-form-input-group>
    </gl-form-group>

    <gl-form-group :label="$options.i18n.corpusName" label-size="sm" label-for="corpus-file">
      <gl-button
        v-if="showFilePickerButton"
        data-testid="upload-attachment-button"
        :disabled="isUploading"
        @click="openFileUpload"
      >
        {{ this.$options.i18n.uploadButtonText }}
      </gl-button>

      <span v-if="isShowingAttachmentName" class="gl-ml-3">
        {{ attachmentName }}
        <gl-button
          v-if="isShowingAttachmentCancel"
          size="small"
          icon="close"
          category="tertiary"
          @click="resetAttachment"
        />
      </span>

      <input
        ref="fileUpload"
        type="file"
        name="corpus_file"
        :accept="$options.VALID_CORPUS_MIMETYPE.mimetype"
        class="gl-display-none"
        @change="onFileUploadChange"
      />
    </gl-form-group>

    <span>{{ this.$options.i18n.uploadMessage }}</span>

    <gl-button
      v-if="showUploadButton"
      data-testid="upload-corpus"
      class="gl-mt-2"
      variant="success"
      @click="beginFileUpload"
    >
      {{ __('Upload file') }}
    </gl-button>

    <div v-if="isUploading" data-testid="upload-status" class="gl-mt-2">
      <gl-loading-icon inline size="sm" />
      {{ progressText }}
      <gl-button size="small" @click="cancelUpload"> {{ __('Cancel') }} </gl-button>
    </div>
  </gl-form>
</template>
