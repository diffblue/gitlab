<script>
import {
  GlIcon,
  GlCollapse,
  GlLink,
  GlButton,
  GlCollapseToggleDirective,
  GlAccordion,
  GlAccordionItem,
  GlSkeletonLoader,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { CODEOWNERS_VALIDATION_I18N, COLLAPSE_ID, DOCS_URL, CODE_TO_MESSAGE } from '../constants';
import validateCodeownerFileQuery from '../queries/validate_codeowner_file.query.graphql';

export default {
  components: {
    GlIcon,
    GlCollapse,
    GlButton,
    GlLink,
    GlAccordion,
    GlAccordionItem,
    GlSkeletonLoader,
  },
  directives: {
    CollapseToggle: GlCollapseToggleDirective,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    filePath: {
      type: String,
      required: true,
    },
    currentRef: {
      type: String,
      required: true,
    },
  },
  apollo: {
    project: {
      query: validateCodeownerFileQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          filePath: this.filePath,
          ref: this.currentRef,
        };
      },
      error() {
        createAlert({ message: this.$options.i18n.errorMessage });
      },
    },
  },
  data() {
    return {
      isValidationVisible: false,
      project: {},
    };
  },
  computed: {
    errorsTotal() {
      return this.project?.repository?.validateCodeownerFile?.total;
    },
    validationErrors() {
      return this.project?.repository?.validateCodeownerFile?.validationErrors;
    },
    collapseIcon() {
      return this.isValidationVisible ? 'chevron-down' : 'chevron-right';
    },
    toggleText() {
      return this.isValidationVisible ? this.$options.i18n.hide : this.$options.i18n.show;
    },
    isSyntaxValid() {
      return this.errorsTotal === 0;
    },
    isLoading() {
      return this.$apollo.queries.project.loading;
    },
  },
  collapseId: COLLAPSE_ID,
  i18n: CODEOWNERS_VALIDATION_I18N,
  docsUrl: DOCS_URL,
  codeToMessage: CODE_TO_MESSAGE,
};
</script>
<template>
  <div class="gl-border-b gl-px-5 gl-py-4 file-validation">
    <gl-skeleton-loader v-if="isLoading" :lines="1" />
    <template v-else>
      <div v-if="errorsTotal">
        <gl-icon name="status_warning" class="gl-mr-2 gl-text-red-500" />
        <span data-testid="invalid-syntax-text">{{ $options.i18n.syntaxErrors(errorsTotal) }}</span>
        <gl-button
          v-collapse-toggle="$options.collapseId"
          variant="link"
          data-testid="collapse-toggle"
          class="gl-ml-2"
        >
          <gl-icon :name="collapseIcon" />
          {{ toggleText }}
        </gl-button>
        <gl-collapse :id="$options.collapseId" v-model="isValidationVisible">
          <gl-accordion :header-level="3" class="gl-mb-4 gl-ml-6 gl-mt-2">
            <gl-accordion-item
              v-for="error in validationErrors"
              :key="error.code"
              :title="`${$options.codeToMessage[error.code]} (${error.lines.length})`"
            >
              <ul>
                <li v-for="line in error.lines" :key="line">
                  <gl-link :href="`#L${line}`">{{ $options.i18n.line }} {{ line }}</gl-link>
                </li>
              </ul>
            </gl-accordion-item>
          </gl-accordion>
          <gl-link
            :href="$options.docsUrl"
            target="_blank"
            class="gl-ml-6"
            data-testid="docs-link"
            >{{ $options.i18n.docsLink }}</gl-link
          >
        </gl-collapse>
      </div>
      <div v-else-if="isSyntaxValid">
        <gl-icon name="check" class="gl-mr-4 gl-text-green-500" />
        <span data-testid="valid-syntax-text">{{ $options.i18n.syntaxValid }}</span>
      </div>
    </template>
  </div>
</template>
