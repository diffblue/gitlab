<script>
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import ClipboardJS from 'clipboard';
import { getBaseURL, setUrlParams, redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { sprintf, s__, __ } from '~/locale';
import { CODE_SNIPPET_SOURCE_URL_PARAM } from '~/ci/pipeline_editor/components/code_snippet_alert/constants';
import SourceEditor from '~/vue_shared/components/source_editor.vue';
import { CONFIGURATION_SNIPPET_MODAL_ID } from './constants';

export default {
  CONFIGURATION_SNIPPET_MODAL_ID,
  components: {
    GlModal,
    GlSprintf,
    GlLink,
    SourceEditor,
  },
  i18n: {
    helpText: __(
      'This code snippet contains everything reflected in the configuration form. Copy and paste it into %{linkStart}.gitlab-ci.yml%{linkEnd} file and save your changes. Future %{scanType} scans will use these settings.',
    ),
    modalTitle: s__('SecurityConfiguration|%{scanType} configuration code snippet'),
    primaryText: s__('SecurityConfiguration|Copy code and open .gitlab-ci.yml file'),
    secondaryText: s__('SecurityConfiguration|Copy code only'),
    cancelText: __('Cancel'),
  },
  props: {
    ciYamlEditUrl: {
      type: String,
      required: true,
    },
    yaml: {
      type: String,
      required: true,
    },
    redirectParam: {
      type: String,
      required: true,
    },
    scanType: {
      type: String,
      required: true,
    },
  },
  computed: {
    modalTitle() {
      return sprintf(this.$options.i18n.modalTitle, {
        scanType: this.scanType,
      });
    },
    editorOptions() {
      return {
        readOnly: true,
        lineNumbers: 'off',
        folding: false,
        renderIndentGuides: false,
        renderLineHighlight: 'none',
        lineDecorationsWidth: 0,
        occurrencesHighlight: false,
        hideCursorInOverviewRuler: true,
        overviewRulerBorder: false,
      };
    },
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    resetEditor() {
      this.$refs.editor.getEditor().layout();
    },
    onHide() {
      this.clipboard?.destroy();
    },
    copySnippet(andRedirect = true) {
      const id = andRedirect ? 'copy-yaml-snippet-and-edit-button' : 'copy-yaml-snippet-button';
      const clipboard = new ClipboardJS(`#${id}`, {
        text: () => this.yaml,
      });
      clipboard.on('success', () => {
        if (andRedirect) {
          const url = new URL(this.ciYamlEditUrl, getBaseURL());
          // eslint-disable-next-line import/no-deprecated
          redirectTo(
            setUrlParams(
              {
                [CODE_SNIPPET_SOURCE_URL_PARAM]: this.redirectParam,
              },
              url,
            ),
          );
        }
      });
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :action-primary="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
      text: $options.i18n.primaryText,
      attributes: { variant: 'confirm', id: 'copy-yaml-snippet-and-edit-button' },
    } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
    :action-secondary="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
      text: $options.i18n.secondaryText,
      attributes: { variant: 'default', id: 'copy-yaml-snippet-button' },
    } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
    :action-cancel="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
      text: $options.i18n.cancelText,
    } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
    :modal-id="$options.CONFIGURATION_SNIPPET_MODAL_ID"
    :title="modalTitle"
    @hide="onHide"
    @shown="resetEditor"
    @primary="copySnippet"
    @secondary="copySnippet(false)"
  >
    <p class="gl-text-gray-500" data-testid="configuration-modal-help-text">
      <gl-sprintf :message="$options.i18n.helpText">
        <template #link="{ content }">
          <gl-link :href="ciYamlEditUrl" target="_blank">
            {{ content }}
          </gl-link>
        </template>
        <template #scanType>
          {{ scanType }}
        </template>
      </gl-sprintf>
    </p>

    <div
      class="gl-w-full gl-h-full gl-border-1 gl-border-solid gl-border-gray-100"
      data-testid="configuration-modal-yaml-snippet"
    >
      <source-editor ref="editor" :value="yaml" file-name="*.yml" :editor-options="editorOptions" />
    </div>
  </gl-modal>
</template>
