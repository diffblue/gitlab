import { s__ } from '~/locale';

export const MESSAGE_TYPES = {
  USER: 'user',
  TANUKI: 'tanuki',
};

export const SOURCE_TYPES = {
  HANDBOOK: {
    value: 'handbook',
    icon: 'book',
  },
  DOC: {
    value: 'doc',
    icon: 'documents',
  },
  BLOG: {
    value: 'blog',
    icon: 'list-bulleted',
  },
};

export const ERROR_MESSAGE = s__(
  'TanukiBot|There was an error communicating with Tanuki Bot. Please reach out to GitLab support for more assistance or try again later.',
);

export const TANUKI_BOT_FEEDBACK_ISSUE_URL = 'https://gitlab.com/gitlab-org/gitlab/-/issues/408527';
