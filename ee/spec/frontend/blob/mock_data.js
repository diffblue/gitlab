export const propsMock = {
  currentRef: 'current-ref',
  projectPath: 'my-namespace/my-project',
  filePath: 'CODEOWNERS',
};

export const validateCodeownerFile = {
  total: 6,
  validationErrors: [
    {
      code: 'invalid_entry_owner_format',
      lines: [2, 4],
      __typename: 'RepositoryCodeownerError',
    },
    {
      code: 'missing_entry_owner',
      lines: [5, 6],
      __typename: 'RepositoryCodeownerError',
    },
    {
      code: 'invalid_section_format',
      lines: [36],
      __typename: 'RepositoryCodeownerError',
    },
    {
      code: 'invalid_section_owner_format',
      lines: [43],
      __typename: 'RepositoryCodeownerError',
    },
  ],
  __typename: 'RepositoryCodeownerValidation',
};

export const valdateCodeownerFileNoErrors = {
  total: 0,
  validationErrors: [],
  __typename: 'RepositoryCodeownerValidation',
};
