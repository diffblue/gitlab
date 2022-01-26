import { s__ } from '~/locale';

export const MAX_LIST_COUNT = 25;
export const MAX_FILE_SIZE = 5e9;

export const VALID_CORPUS_MIMETYPE = {
  mimetype: 'application/zip',
};

export const I18N = {
  fileTooLarge: s__('CorpusManagement|File too large, Maximum 5 GB'),
  invalidName: s__(
    'CorpusManagement|Filename can contain only lowercase letters (a-z), uppercase letter (A-Z), numbers (0-9), dots (.), hyphens (-), or underscores (_).',
  ),
};

export const ERROR_RESPONSE = {
  packageNameInvalid: 'package_name is invalid',
  /* eslint-disable-next-line @gitlab/require-i18n-strings */
  notFound: '404 Not Found',
};
