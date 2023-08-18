<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import InlineFindingsGutterIcon from 'ee_component/diffs/components/inline_findings_gutter_icon.vue';
import InlineFindingsGutterIconDropdown from 'ee_component/diffs/components/inline_findings_gutter_icon_dropdown.vue';

export default {
  components: {
    InlineFindingsGutterIcon,
    InlineFindingsGutterIconDropdown,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    inlineFindingsExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
    filePath: {
      type: String,
      required: true,
    },
    codeQuality: {
      type: Array,
      required: false,
      default: () => [],
    },
    sast: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    sastReportsInInlineDiff() {
      return this.glFeatures.sastReportsInInlineDiff;
    },
  },
  methods: {
    showInlineFindingsEvent() {
      this.$emit('showInlineFindings');
    },
  },
};
</script>

<template>
  <div v-if="sastReportsInInlineDiff">
    <inline-findings-gutter-icon-dropdown
      :code-quality="codeQuality"
      :sast="sast"
      :file-path="filePath"
    />
  </div>
  <div v-else>
    <inline-findings-gutter-icon
      :inline-findings-expanded="inlineFindingsExpanded"
      :code-quality="codeQuality"
      :sast="sast"
      :file-path="filePath"
      @showInlineFindings="showInlineFindingsEvent"
    />
  </div>
</template>
