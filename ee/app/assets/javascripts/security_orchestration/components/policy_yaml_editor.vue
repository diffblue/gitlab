<script>
import SourceEditor from '~/vue_shared/components/source_editor.vue';
import { EDITOR_READY_EVENT } from '~/editor/constants';
import { PolicySchemaExtension } from './policy_editor_schema_ext';

export default {
  components: {
    SourceEditor,
  },
  inject: ['namespacePath', 'namespaceType'],
  props: {
    policyType: {
      type: String,
      required: false,
      default: '',
    },
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
    registerSchema({ detail: { instance } }) {
      instance.use({ definition: PolicySchemaExtension });
      instance.registerSecurityPolicySchema({
        namespacePath: this.namespacePath,
        namespaceType: this.namespaceType,
        policyType: this.policyType,
      });
    },
  },
  readyEvent: EDITOR_READY_EVENT,
};
</script>

<template>
  <source-editor
    :value="value"
    file-name="*.yaml"
    :editor-options="editorOptions"
    @[$options.readyEvent]="registerSchema($event)"
    @input="onInput"
  />
</template>
