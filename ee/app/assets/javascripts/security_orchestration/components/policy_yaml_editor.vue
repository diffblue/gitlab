<script>
import SourceEditor from '~/vue_shared/components/source_editor.vue';

export default {
  components: {
    SourceEditor,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    readOnly: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    editorOptions() {
      return {
        lineNumbers: 'off',
        folding: false,
        // This represents 14px, which matches the number of pixels added to the left via glyphMargin
        padding: { top: 14 },
        renderIndentGuides: false,
        renderWhitespace: 'boundary',
        renderLineHighlight: 'none',
        lineDecorationsWidth: 0,
        lineNumbersMinChars: 0,
        occurrencesHighlight: false,
        hideCursorInOverviewRuler: true,
        overviewRulerBorder: false,
        readOnly: this.readOnly,
      };
    },
  },
  methods: {
    onInput(val) {
      this.$emit('input', val);
    },
  },
};
</script>

<template>
  <source-editor
    :value="value"
    file-name="*.yaml"
    :editor-options="editorOptions"
    @input="onInput"
  />
</template>
