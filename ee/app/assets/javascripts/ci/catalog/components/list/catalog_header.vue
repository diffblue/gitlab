<script>
import { GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlLink,
  },
  inject: ['pageTitle', 'pageDescription'],
  i18n: {
    learnMore: s__('CiCatalog|Learn more'),
  },
  learnMorePath: helpPagePath('architecture/blueprints/ci_pipeline_components/index'),
};
</script>
<template>
  <div class="gl-border-b-1 gl-border-gray-100 gl-border-b-solid">
    <h1 class="gl-font-size-h-display">{{ pageTitle }}</h1>
    <p>
      <span>{{ pageDescription }}</span>
      <gl-link :href="$options.learnMorePath" target="_blank">{{
        $options.i18n.learnMore
      }}</gl-link>
    </p>
  </div>
</template>
