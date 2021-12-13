<script>
import { GlFormGroup, GlFormInput, GlLoadingIcon, GlModal, GlTab } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { __, s__ } from '~/locale';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import MetricsImage from './metrics_image.vue';
import createStore from './store';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlLoadingIcon,
    GlModal,
    GlTab,
    MetricsImage,
    UploadDropzone,
  },
  inject: ['canUpdate', 'projectId', 'iid'],
  data() {
    return {
      currentFiles: [],
      modalVisible: false,
      modalUrl: '',
    };
  },
  store: createStore(),
  computed: {
    ...mapState(['metricImages', 'isLoadingMetricImages', 'isUploadingImage']),
    actionPrimaryProps() {
      return {
        text: this.$options.i18n.modalUpload,
        attributes: {
          loading: this.isUploadingImage,
          disabled: this.isUploadingImage,
          category: 'primary',
          variant: 'success',
        },
      };
    },
  },
  mounted() {
    this.setInitialData({ issueIid: this.iid, projectId: this.projectId });
    this.fetchMetricImages();
  },
  methods: {
    ...mapActions(['fetchMetricImages', 'uploadImage', 'setInitialData']),
    clearInputs() {
      this.modalVisible = false;
      this.modalUrl = '';
      this.currentFile = false;
    },
    openMetricDialog(files) {
      this.modalVisible = true;
      this.currentFiles = files;
    },
    async onUpload() {
      try {
        await this.uploadImage({ files: this.currentFiles, url: this.modalUrl });
        // Error case handled within action
      } finally {
        this.clearInputs();
      }
    },
  },
  i18n: {
    modalUpload: __('Upload'),
    modalCancel: __('Cancel'),
    modalTitle: s__('Incidents|Add a URL'),
    modalDescription: s__(
      'Incidents|You can optionally add a URL to link users to the original graph.',
    ),
    dropDescription: s__(
      'Incidents|Drop or %{linkStart}upload%{linkEnd} a metric screenshot to attach it to the incident',
    ),
  },
};
</script>

<template>
  <gl-tab :title="s__('Incident|Metrics')" data-testid="metrics-tab">
    <div v-if="isLoadingMetricImages">
      <gl-loading-icon class="gl-p-5" size="sm" />
    </div>
    <gl-modal
      modal-id="upload-metric-modal"
      size="sm"
      :action-primary="actionPrimaryProps"
      :action-cancel="{ text: $options.i18n.modalCancel }"
      :title="$options.i18n.modalTitle"
      :visible="modalVisible"
      @hidden="clearInputs"
      @primary.prevent="onUpload"
    >
      <p>{{ $options.i18n.modalDescription }}</p>
      <gl-form-group
        :label="__('URL')"
        label-for="upload-url-input"
        :description="s__('Incidents|Must start with http or https')"
      >
        <gl-form-input id="upload-url-input" v-model="modalUrl" />
      </gl-form-group>
    </gl-modal>
    <metrics-image v-for="metric in metricImages" :key="metric.id" v-bind="metric" />
    <upload-dropzone
      v-if="canUpdate"
      :drop-description-message="$options.i18n.dropDescription"
      @change="openMetricDialog"
    />
  </gl-tab>
</template>
