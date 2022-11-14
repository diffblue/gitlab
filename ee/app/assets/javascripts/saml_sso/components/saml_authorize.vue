<script>
import { GlAlert, GlButton, GlFormCheckbox, GlLink, GlSprintf } from '@gitlab/ui';
import { I18N, REMEMBER_ME_PARAM } from '../constants';

export default {
  components: {
    GlAlert,
    GlButton,
    GlFormCheckbox,
    GlLink,
    GlSprintf,
  },
  i18n: I18N,
  inject: [
    'groupName',
    'groupUrl',
    'rememberable',
    'samlUrl',
    'username',
    'userFullName',
    'userUrl',
  ],
  data() {
    return {
      href: this.samlUrl,
    };
  },
  methods: {
    onChange(remember) {
      const url = new URL(this.href, document.location);
      if (remember) {
        url.searchParams.set(REMEMBER_ME_PARAM, '1');
      } else {
        url.searchParams.delete(REMEMBER_ME_PARAM);
      }
      this.href = url.href;
    },
  },
};
</script>

<template>
  <div>
    <h4 class="gl-mt-0">
      <gl-sprintf :message="$options.i18n.authorizeTitle">
        <template #groupName>
          <gl-link :href="groupUrl" class="gl-font-size-inherit" target="_blank">{{
            groupName
          }}</gl-link>
        </template>
      </gl-sprintf>
    </h4>
    <p>
      <gl-sprintf :message="$options.i18n.authorizeInfo">
        <template #groupName>
          {{ groupName }}
        </template>
      </gl-sprintf>
    </p>
    <gl-alert variant="warning" class="gl-mb-5" :dismissible="false">
      <gl-sprintf :message="$options.i18n.authorizeAlert">
        <template #groupName>
          {{ groupName }}
        </template>
        <template #username>
          <gl-link :href="userUrl" class="gl-font-size-inherit" target="_blank"
            >{{ userFullName }} @{{ username }}</gl-link
          >
        </template>
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
      </gl-sprintf>
    </gl-alert>
    <gl-form-checkbox v-if="rememberable" @change="onChange"
      >{{ $options.i18n.rememberMe }}
    </gl-form-checkbox>
    <gl-button
      block
      variant="confirm"
      class="gl-mt-3"
      data-qa-selector="saml_sso_signin_button"
      :href="href"
      data-method="post"
      >{{ $options.i18n.authorizeButton }}</gl-button
    >
  </div>
</template>
