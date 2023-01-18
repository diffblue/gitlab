<script>
import { GlModal, GlSprintf, GlModalDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import Cer from './cer.vue';
import P12 from './p12.vue';
import Mobileprovision from './mobileprovision.vue';

export default {
  components: {
    GlModal,
    GlSprintf,
    Cer,
    P12,
    Mobileprovision,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  props: {
    secureFile: {
      type: Object,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
  },
  i18n: {
    metadataLabel: __('View File Metadata'),
    metadataModalTitle: s__('SecureFiles|%{name} Metadata'),
  },
  metadataModalId: 'metadataModalId',
  methods: {
    cerFile() {
      return this.secureFile.file_extension === 'cer';
    },
    p12File() {
      return this.secureFile.file_extension === 'p12';
    },
    mobileprovisionFile() {
      return this.secureFile.file_extension === 'mobileprovision';
    },
  },
};
</script>

<template>
  <gl-modal :ref="modalId" :modal-id="modalId" title-tag="h4" category="primary" hide-footer>
    <template #modal-title>
      <gl-sprintf :message="$options.i18n.metadataModalTitle">
        <template #name>{{ secureFile.name }}</template>
      </gl-sprintf>
    </template>

    <cer v-if="cerFile()" :metadata="secureFile.metadata" />
    <p12 v-if="p12File()" :metadata="secureFile.metadata" />
    <mobileprovision v-if="mobileprovisionFile()" :metadata="secureFile.metadata" />
  </gl-modal>
</template>
