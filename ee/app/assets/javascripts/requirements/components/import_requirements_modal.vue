<script>
import { GlModal, GlFormGroup, GlSprintf } from '@gitlab/ui';

export default {
  components: {
    GlModal,
    GlFormGroup,
    GlSprintf,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      file: null,
    };
  },
  computed: {
    importDisabled() {
      return !this.file;
    },
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    hide() {
      this.$refs.modal.hide();
    },
    handleCSVFile(e) {
      const [file] = e.target.files;
      this.file = file;
    },
    handleImport() {
      const { projectPath, file } = this;

      if (!file) {
        return;
      }

      this.$emit('import', { file, projectPath });
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    size="sm"
    modal-id="import-requirements"
    :title="__('Import requirements')"
    :ok-title="__('Import requirements')"
    :ok-disabled="importDisabled"
    ok-only
    @ok="handleImport"
  >
    <p>
      {{
        __(
          "Your requirements will be imported in the background. After it's finished, you'll get a confirmation email.",
        )
      }}
    </p>

    <div>
      <gl-form-group
        label="Upload CSV file"
        class="gl-text-truncate"
        label-for="import-requirements-file-input"
      >
        <input
          id="import-requirements-file-input"
          ref="fileInput"
          class="gl-mt-3 gl-mb-2"
          type="file"
          accept=".csv,text/csv"
          @change="handleCSVFile"
        />
      </gl-form-group>
    </div>

    <p class="text-secondary">
      <gl-sprintf
        :message="
          __(
            'Your file must contain a column named %{codeStart}title%{codeEnd}. A %{codeStart}description%{codeEnd} column is optional. The maximum file size allowed is 10 MB.',
          )
        "
      >
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
      </gl-sprintf>
    </p>
  </gl-modal>
</template>
