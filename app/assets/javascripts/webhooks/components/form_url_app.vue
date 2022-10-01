<script>
import { GlFormGroup, GlFormInput, GlFormRadio } from '@gitlab/ui';
import FormUrlMaskItem from './form_url_mask_item.vue';

export default {
  components: {
    FormUrlMaskItem,
    GlFormGroup,
    GlFormInput,
    GlFormRadio,
  },
  data() {
    return {
      maskEnabled: false,
    };
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :label="__('URL')"
      label-for="webhook-url"
      :description="
        s__('Webhooks|URL must be percent-encoded if it contains one or more special characters.')
      "
    >
      <gl-form-input id="webhook-url" :placeholder="__('http://example.com/trigger-ci.json')" />
    </gl-form-group>
    <div class="gl-mt-5">
      <gl-form-radio v-model="maskEnabled" :value="false">{{
        s__('Webhooks|Show full URL')
      }}</gl-form-radio>
      <gl-form-radio v-model="maskEnabled" :value="true">{{
        s__('Webhooks|Mask portions of URL')
      }}</gl-form-radio>

      <div v-show="maskEnabled" class="gl-ml-6">
        <form-url-mask-item />
        <gl-form-group :label="s__('Webhooks|URL preview')" label-for="webhook-url-preview">
          <gl-form-input id="webhook-url-preview" readonly />
        </gl-form-group>
      </div>
    </div>
  </div>
</template>
