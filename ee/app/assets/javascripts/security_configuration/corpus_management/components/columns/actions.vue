<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlModal,
  },
  directives: {
    GlModalDirective,
  },
  inject: ['canReadCorpus', 'canDestroyCorpus'],
  props: {
    corpus: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    deleteCorpusMessage: s__('Corpus Management|Are you sure you want to delete the corpus?'),
  },
  modal: {
    actionPrimary: {
      text: __('Delete corpus'),
      attributes: { variant: 'danger', 'data-testid': 'modal-confirm' },
    },
    actionCancel: {
      text: __('Cancel'),
    },
  },
  computed: {
    downloadPath() {
      return this.corpus.package.packageFiles.nodes[0].downloadPath;
    },
    name() {
      return this.corpus.package.name;
    },
    directiveName() {
      return `confirmation-modal-${this.name}`;
    },
  },
};
</script>
<template>
  <span>
    <gl-button
      v-if="canReadCorpus"
      class="gl-mr-2"
      icon="download"
      :href="downloadPath"
      :aria-label="__('Download')"
      data-testid="download-corpus"
    />
    <gl-button
      v-if="canDestroyCorpus"
      v-gl-modal-directive="directiveName"
      icon="remove"
      category="secondary"
      variant="danger"
      :aria-label="__('Delete')"
      data-testid="destroy-corpus"
    />

    <gl-modal
      header-class="gl-border-b-initial"
      body-class="gl-display-none"
      size="sm"
      :title="$options.i18n.deleteCorpusMessage"
      :modal-id="directiveName"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @primary="$emit('delete', corpus)"
    />
  </span>
</template>
