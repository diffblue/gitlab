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
  props: {
    states: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    corpusName: s__('CorpusManagement|Corpus name'),
    corpusFile: s__('CorpusManagement|Corpus file'),
    uploadButtonText: __('Choose File...'),
    uploadMessage: s__('CorpusManagement|Corpus files must be in *.zip format. Maximum 5 GB'),
  },
  data() {
    return {
      attachmentName: '',
      corpusName: '',
      files: [],
    };
  },
  computed: {
    hasAttachment() {
      return Boolean(this.attachmentName);
    },
    hasValidName() {
      return !this.nameError;
    },
    hasValidFile() {
      return !this.fileError;
    },
    isShowingUploadText() {
      return this.hasValidFile && !this.isUploaded;
    },
    isShowingAttachmentName() {
      return this.hasAttachment && !this.isLoading;
    },
    isShowingAttachmentCancel() {
      return !this.isUploaded && !this.isUploading;
    },
    isUploading() {
      return this.states?.isUploading;
    },
    isUploaded() {
      return this.progress === 100;
    },
    isUploadButtonEnabled() {
      return !this.corpusName;
    },
    showUploadButton() {
      return this.hasAttachment && !this.isUploading && !this.isUploaded;
    },
    showFilePickerButton() {
      return !this.isUploaded;
    },
    progress() {
      return this.states?.progress;
    },
    progressText() {
      return sprintf(__('Attaching File - %{progress}'), { progress: `${this.progress}%` });
    },
    nameError() {
      return this.states?.errors.name;
    },
    fileError() {
      return this.states?.errors.file;
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
      this.$emit('resetCorpus');
    },
    cancelUpload() {
      this.$emit('resetCorpus');
    },
    openFileUpload() {
      this.$refs.fileUpload.click();
    },
    beginFileUpload() {
      this.$emit('beginFileUpload', { name: this.corpusName, files: this.files });
    },
    onFileUploadChange(e) {
      this.attachmentName = e.target.files[0].name;
      this.files = e.target.files;
      this.$emit('resetCorpus');
    },
  },
  VALID_CORPUS_MIMETYPE,
};
</script>
<template>
  <gl-form>
    <gl-form-group
      :label="$options.i18n.corpusName"
      label-size="sm"
      label-for="corpus-name"
      data-testid="corpus-name-group"
      :invalid-feedback="nameError"
      :state="hasValidName"
    >
      <gl-form-input-group>
        <gl-form-input
          id="corpus-name"
          ref="input"
          v-model="corpusName"
          data-testid="corpus-name"
          :state="hasValidName"
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

    <gl-form-group
      :label="$options.i18n.corpusFile"
      label-size="sm"
      label-for="corpus-file"
      data-testid="corpus-file-group"
      :invalid-feedback="fileError"
      :state="hasValidFile"
    >
      <gl-button
        v-if="showFilePickerButton"
        data-testid="upload-attachment-button"
        :disabled="isUploading"
        @click="openFileUpload"
      >
        {{ $options.i18n.uploadButtonText }}
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

    <span v-if="isShowingUploadText" class="gl-text-gray-500">{{
      $options.i18n.uploadMessage
    }}</span>

    <gl-form-group>
      <gl-button
        v-if="showUploadButton"
        data-testid="upload-corpus"
        class="gl-mt-2"
        :disabled="isUploadButtonEnabled"
        category="primary"
        variant="confirm"
        @click="beginFileUpload"
      >
        {{ __('Upload file') }}
      </gl-button>
    </gl-form-group>

    <div v-if="isUploading" data-testid="upload-status" class="gl-mt-2">
      <gl-loading-icon inline size="sm" />
      {{ progressText }}
      <gl-button size="small" data-testid="cancel-upload" @click="cancelUpload">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>
