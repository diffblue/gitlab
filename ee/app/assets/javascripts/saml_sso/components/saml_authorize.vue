<script>
import { GlButton, GlFormCheckbox, GlLink, GlSprintf } from '@gitlab/ui';
import { mergeUrlParams, removeParams } from '~/lib/utils/url_utility';
import { I18N, REMEMBER_ME_PARAM } from '../constants';

export default {
  components: {
    GlButton,
    GlFormCheckbox,
    GlLink,
    GlSprintf,
  },
  i18n: I18N,
  inject: ['groupName', 'groupUrl', 'rememberable', 'samlUrl', 'signInButtonText'],
  data() {
    return {
      href: this.samlUrl,
    };
  },
  methods: {
    onChange(remember) {
      if (remember) {
        this.href = mergeUrlParams({ [REMEMBER_ME_PARAM]: '1' }, this.href);
      } else {
        this.href = removeParams([REMEMBER_ME_PARAM], this.href);
      }
    },
  },
};
</script>

<template>
  <div>
    <h4 class="gl-mt-0">
      <gl-sprintf :message="$options.i18n.signInTitle">
        <template #groupName>
          <gl-link :href="groupUrl" class="gl-font-size-inherit" target="_blank">{{
            groupName
          }}</gl-link>
        </template>
      </gl-sprintf>
    </h4>

    <p>
      <gl-sprintf :message="$options.i18n.signInInfo">
        <template #groupName>{{ groupName }}</template>
      </gl-sprintf>
    </p>

    <gl-form-checkbox v-if="rememberable" autocomplete="off" @change="onChange"
      >{{ $options.i18n.rememberMe }}
    </gl-form-checkbox>

    <gl-button
      block
      variant="confirm"
      class="gl-mt-3"
      data-qa-selector="saml_sso_signin_button"
      :href="href"
      data-method="post"
      >{{ signInButtonText }}</gl-button
    >
  </div>
</template>
