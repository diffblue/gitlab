<script>
import { GlDropdown, GlButton, GlIcon } from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';

export default {
  components: {
    GlDropdown,
    GlButton,
    GlIcon,
    MarkdownField,
  },
  data() {
    return {
      isSubmitting: false,
      note: '',
    };
  },
  computed: {
    ...mapGetters(['getNotesData', 'getNoteableData', 'noteableType']),
  },
  methods: {
    ...mapActions('batchComments', ['publishReview']),
    async submitReview() {
      const noteData = {
        noteable_type: this.noteableType,
        noteable_id: this.getNoteableData.id,
        note: this.note,
      };

      this.isSubmitting = true;

      await this.publishReview(noteData);

      this.isSubmitting = false;
    },
  },
  restrictedToolbarItems: ['full-screen'],
};
</script>

<template>
  <gl-dropdown right class="submit-review-dropdown" variant="info">
    <template #button-content>
      {{ __('Finish review') }}
      <gl-icon class="dropdown-chevron" name="chevron-up" />
    </template>
    <form @submit.prevent="submitReview">
      <label for="review-note-body" class="gl-font-weight-bold gl-mb-3">{{
        __('Summary comment (optional)')
      }}</label>
      <div class="common-note-form gfm-form">
        <div
          class="comment-warning-wrapper gl-border-solid gl-border-1 gl-rounded-base gl-border-gray-100"
        >
          <markdown-field
            ref="markdownField"
            :is-submitting="isSubmitting"
            :add-spacing-classes="false"
            :textarea-value="note"
            :markdown-preview-path="getNoteableData.preview_note_path"
            :markdown-docs-path="getNotesData.markdownDocsPath"
            :quick-actions-docs-path="getNotesData.quickActionsDocsPath"
            :restricted-tool-bar-items="$options.restrictedToolbarItems"
            :force-autosize="false"
          >
            <template #textarea>
              <textarea
                id="review-note-body"
                ref="textarea"
                v-model="note"
                dir="auto"
                :disabled="isSubmitting"
                name="review[note]"
                class="note-textarea js-gfm-input markdown-area"
                data-supports-quick-actions="true"
                :aria-label="__('Comment')"
                :placeholder="__('Write a comment or drag your files here…')"
                @keydown.meta.enter="submitReview"
                @keydown.ctrl.enter="submitReview"
              ></textarea>
            </template>
          </markdown-field>
        </div>
      </div>
      <div class="gl-display-flex gl-mt-5">
        <gl-button
          :loading="isSubmitting"
          variant="info"
          type="submit"
          class="gl-ml-auto js-no-auto-disable"
        >
          {{ __('Submit review') }}
        </gl-button>
      </div>
    </form>
  </gl-dropdown>
</template>
