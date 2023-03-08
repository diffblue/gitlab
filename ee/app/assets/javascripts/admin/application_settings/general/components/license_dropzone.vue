<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { createAlert } from '~/alert';
import {
  DROPZONE_DESCRIPTION_TEXT,
  FILE_UPLOAD_ERROR_MESSAGE,
  FILE_DROP_ERROR_MESSAGE,
  DROP_TO_START_MESSAGE,
} from '../constants';

const VALID_LICENSE_FILE_MIMETYPES = ['.gitlab_license', '.gitlab-license', '.txt'];
const FILE_EXTENSION_REGEX = /\.(gitlab[-_]license|txt)$/;

const isValidLicenseFile = ({ name }) => {
  return FILE_EXTENSION_REGEX.test(name);
};

export default {
  name: 'LicenseNewApp',
  components: {
    UploadDropzone,
    GlLink,
    GlSprintf,
  },
  VALID_LICENSE_FILE_MIMETYPES,
  isValidLicenseFile,
  i18n: {
    DROPZONE_DESCRIPTION_TEXT,
    FILE_UPLOAD_ERROR_MESSAGE,
    FILE_DROP_ERROR_MESSAGE,
    DROP_TO_START_MESSAGE,
  },
  data() {
    return { fileName: null };
  },
  computed: {
    dropzoneDescription() {
      return this.fileName ?? this.$options.i18n.DROPZONE_DESCRIPTION_TEXT;
    },
  },
  methods: {
    onChange(file) {
      this.fileName = file?.name;
    },
    onError() {
      createAlert({ message: this.$options.i18n.FILE_UPLOAD_ERROR_MESSAGE });
    },
  },
};
</script>
<template>
  <upload-dropzone
    input-field-name="license[data_file]"
    :is-file-valid="$options.isValidLicenseFile"
    :valid-file-mimetypes="$options.VALID_LICENSE_FILE_MIMETYPES"
    :should-update-input-on-file-drop="true"
    :single-file-selection="true"
    :enable-drag-behavior="false"
    :drop-to-start-message="$options.i18n.DROP_TO_START_MESSAGE"
    @change="onChange"
    @error="onError"
  >
    <template #upload-text="{ openFileUpload }">
      <gl-sprintf :message="dropzoneDescription">
        <template #link="{ content }">
          <gl-link @click.stop="openFileUpload">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>

    <template #invalid-drag-data-slot>
      {{ $options.i18n.FILE_DROP_ERROR_MESSAGE }}
    </template>
  </upload-dropzone>
</template>
