<script>
import { GlButton, GlCard, GlIcon, GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { mapActions } from 'vuex';
import { __, s__ } from '~/locale';

export default {
  i18n: {
    modalDelete: __('Delete'),
    modalDescription: s__('Incident|Are you sure you wish to delete this image?'),
    modalCancel: __('Cancel'),
    modalTitle: s__('Incident|Deleting %{filename}'),
  },
  components: {
    GlButton,
    GlCard,
    GlIcon,
    GlLink,
    GlModal,
    GlSprintf,
  },
  inject: ['canUpdate'],
  props: {
    id: {
      type: Number,
      required: true,
    },
    filePath: {
      type: String,
      required: true,
    },
    filename: {
      type: String,
      required: true,
    },
    url: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isCollapsed: false,
      isDeleting: false,
      modalVisible: false,
    };
  },
  computed: {
    actionPrimaryProps() {
      return {
        text: this.$options.i18n.modalDelete,
        attributes: {
          loading: this.isDeleting,
          disabled: this.isDeleting,
          category: 'primary',
          variant: 'danger',
        },
      };
    },
    arrowIconName() {
      return this.isCollapsed ? 'chevron-right' : 'chevron-down';
    },
    bodyClass() {
      return [
        'gl-border-1',
        'gl-border-t-solid',
        'gl-border-gray-100',
        { 'gl-display-none': this.isCollapsed },
      ];
    },
  },
  methods: {
    ...mapActions(['deleteImage']),
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;
    },
    async onDelete() {
      try {
        this.isDeleting = true;
        await this.deleteImage(this.id);
      } finally {
        this.isDeleting = false;
        this.modalVisible = false;
      }
    },
  },
};
</script>

<template>
  <gl-card
    class="collapsible-card border gl-p-0 gl-mb-5"
    header-class="gl-display-flex gl-align-items-center gl-border-b-0 gl-py-3"
    :body-class="bodyClass"
  >
    <gl-modal
      body-class="gl-pb-0! gl-min-h-6!"
      modal-id="delete-metric-modal"
      size="sm"
      :visible="modalVisible"
      :action-primary="actionPrimaryProps"
      :action-cancel="{ text: $options.i18n.modalCancel }"
      @primary.prevent="onDelete"
      @hidden="modalVisible = false"
    >
      <template #modal-title>
        <gl-sprintf :message="$options.i18n.modalTitle">
          <template #filename>
            {{ filename }}
          </template>
        </gl-sprintf>
      </template>
      <p>{{ $options.i18n.modalDescription }}</p>
    </gl-modal>
    <template #header>
      <div class="gl-w-full gl-display-flex gl-flex-direction-row gl-justify-content-space-between">
        <div class="gl-display-flex gl-flex-direction-row gl-align-items-center gl-w-full">
          <gl-button
            class="collapsible-card-btn gl-display-flex gl-text-decoration-none gl-reset-color! gl-hover-text-blue-800! gl-shadow-none!"
            :aria-label="filename"
            variant="link"
            category="tertiary"
            data-testid="collapse-button"
            @click="toggleCollapsed"
          >
            <gl-icon class="gl-mr-2" :name="arrowIconName" />
          </gl-button>
          <gl-link v-if="url" :href="url">
            {{ filename }}
          </gl-link>
          <span v-else>{{ filename }}</span>
          <gl-button
            v-if="canUpdate"
            class="gl-ml-auto"
            icon="remove"
            :aria-label="__('Delete')"
            data-testid="delete-button"
            @click="modalVisible = true"
          />
        </div>
      </div>
    </template>
    <div
      v-show="!isCollapsed"
      class="gl-display-flex gl-flex-direction-column"
      data-testid="metric-image-body"
    >
      <img class="gl-max-w-full gl-align-self-center" :src="filePath" />
    </div>
  </gl-card>
</template>
