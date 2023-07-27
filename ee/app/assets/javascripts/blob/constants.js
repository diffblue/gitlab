import { n__, s__ } from '~/locale';
import { DOCS_URL_IN_EE_DIR } from 'jh_else_ce/lib/utils/url_utility';

export const SYNTAX_ERRORS_TEXT = (count) =>
  n__(
    'CodeownersValidation|Contains %d syntax error.',
    'CodeownersValidation|Contains %d syntax errors.',
    count,
  );

export const SYNTAX_VALID = s__('CodeownersValidation|Syntax is valid.');

export const DOCS_LINK_TEXT = s__('CodeownersValidation|How are errors handled?');

export const SHOW_ERRORS = s__('CodeownersValidation|Show errors');

export const HIDE_ERRORS = s__('CodeownersValidation|Hide errors');

export const COLLAPSE_ID = 'CODEOWNERS_VALIDATION_COLLAPSE';

export const LINE = s__('CodeownersValidation|Line');

export const ERROR_MESSAGE = s__(
  'CodeownersValidation|An error occurred while loading the validation errors. Please try again later.',
);

export const DOCS_URL = `${DOCS_URL_IN_EE_DIR}/user/project/codeowners/reference.html#error-handling-in-code-owners`;

export const CODEOWNERS_VALIDATION_I18N = {
  syntaxValid: SYNTAX_VALID,
  syntaxErrors: SYNTAX_ERRORS_TEXT,
  show: SHOW_ERRORS,
  hide: HIDE_ERRORS,
  docsLink: DOCS_LINK_TEXT,
  line: LINE,
  errorMessage: ERROR_MESSAGE,
};

export const INVALID_SECTION_OWNER_FORMAT = s__('CodeownersValidation|Inaccessible owners');

export const MISSING_ENTRY_OWNER = s__('CodeownersValidation|Zero owners');

export const INVALID_ENTRY_OWNER_FORMAT = s__('CodeownersValidation|Entries with spaces');

export const MISSING_SECTION_NAME = s__('CodeownersValidation|Missing section name');

export const INVALID_APPROVAL_REQUIREMENT = s__(
  'CodeownersValidation|Less than 1 required approvals',
);

export const INVALID_SECTION_FORMAT = s__('CodeownersValidation|Unparsable sections');

export const CODE_TO_MESSAGE = {
  invalid_section_owner_format: INVALID_SECTION_OWNER_FORMAT,
  missing_entry_owner: MISSING_ENTRY_OWNER,
  invalid_entry_owner_format: INVALID_ENTRY_OWNER_FORMAT,
  missing_section_name: MISSING_SECTION_NAME,
  invalid_approval_requirement: INVALID_APPROVAL_REQUIREMENT,
  invalid_section_format: INVALID_SECTION_FORMAT,
};
