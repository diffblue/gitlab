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
    uploadButtonText: __('Choose File...'),
    uploadMessage: s__(
      'CorpusManagement|New corpus needs to be a upload in *.zip format. Maximum 5GB',
    ),
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
      return this.progress === 100;
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

    <span>{{ $options.i18n.uploadMessage }}</span>

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
      <gl-button size="small" data-testid="cancel-upload" @click="cancelUpload">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>
