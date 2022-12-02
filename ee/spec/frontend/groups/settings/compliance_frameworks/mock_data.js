export const suggestedLabelColors = {
  '#000000': 'Black',
  '#0033CC': 'UA blue',
  '#428BCA': 'Moderate blue',
  '#44AD8E': 'Lime green',
};

export const validFetchResponse = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/1',
      name: 'Group 1',
      complianceFrameworks: {
        nodes: [
          {
            id: 'gid://gitlab/ComplianceManagement::Framework/1',
            name: 'GDPR',
            default: true,
            description: 'General Data Protection Regulation',
            pipelineConfigurationFullPath: 'file.yml@group/project',
            color: '#1aaa55',
            __typename: 'ComplianceFramework',
          },
          {
            id: 'gid://gitlab/ComplianceManagement::Framework/2',
            name: 'PCI-DSS',
            default: false,
            description: 'Payment Card Industry-Data Security Standard',
            pipelineConfigurationFullPath: 'file.yml@group/project',
            color: '#6666c4',
            __typename: 'ComplianceFramework',
          },
        ],
        __typename: 'ComplianceFrameworkConnection',
      },
      __typename: 'Namespace',
    },
  },
};

export const emptyFetchResponse = {
  data: {
    namespace: {
      id: 'gid://group-1/Group/1',
      name: 'Group 1',
      default: false,
      complianceFrameworks: {
        nodes: [],
        __typename: 'ComplianceFrameworkConnection',
      },
      __typename: 'Namespace',
    },
  },
};

export const frameworkFoundResponse = {
  id: 'gid://gitlab/ComplianceManagement::Framework/1',
  name: 'GDPR',
  default: false,
  description: 'General Data Protection Regulation',
  pipelineConfigurationFullPath: 'file.yml@group/project',
  color: '#1aaa55',
};

export const validFetchOneResponse = {
  data: {
    namespace: {
      id: 'gid://gitlab/Group/1',
      name: 'Group 1',
      complianceFrameworks: {
        nodes: [
          {
            id: 'gid://gitlab/ComplianceManagement::Framework/1',
            name: 'GDPR',
            default: true,
            description: 'General Data Protection Regulation',
            pipelineConfigurationFullPath: 'file.yml@group/project',
            color: '#1aaa55',
            __typename: 'ComplianceFramework',
          },
        ],
        __typename: 'ComplianceFrameworkConnection',
      },
      __typename: 'Namespace',
    },
  },
};

export const validCreateResponse = {
  data: {
    createComplianceFramework: {
      framework: {
        id: 'gid://gitlab/ComplianceManagement::Framework/1',
        name: 'GDPR',
        default: true,
        description: 'General Data Protection Regulation',
        pipelineConfigurationFullPath: 'file.yml@group/project',
        color: '#1aaa55',
        __typename: 'ComplianceFramework',
      },
      errors: [],
      __typename: 'CreateComplianceFrameworkPayload',
    },
  },
};

export const errorCreateResponse = {
  data: {
    createComplianceFramework: {
      framework: null,
      errors: ['Invalid values given'],
      __typename: 'CreateComplianceFrameworkPayload',
    },
  },
};

export const validUpdateResponse = {
  data: {
    updateComplianceFramework: {
      clientMutationId: null,
      errors: [],
      __typename: 'UpdateComplianceFrameworkPayload',
    },
  },
};

export const errorUpdateResponse = {
  data: {
    updateComplianceFramework: {
      clientMutationId: null,
      errors: ['Invalid values given'],
      __typename: 'UpdateComplianceFrameworkPayload',
    },
  },
};

export const validDeleteResponse = {
  data: {
    destroyComplianceFramework: {
      clientMutationId: null,
      errors: [],
      __typename: 'DestroyComplianceFrameworkPayload',
    },
  },
};

export const errorDeleteResponse = {
  data: {
    destroyComplianceFramework: {
      clientMutationId: null,
      errors: ['graphql error'],
      __typename: 'DestroyComplianceFrameworkPayload',
    },
  },
};

export const validSetDefaultFrameworkResponse = {
  data: {
    updateComplianceFramework: {
      clientMutationId: null,
      errors: [],
      __typename: 'UpdateComplianceFrameworkPayload',
    },
  },
};

export const errorSetDefaultFrameworkResponse = {
  data: {
    updateComplianceFramework: {
      clientMutationId: null,
      errors: ['graphql error'],
      __typename: 'UpdateComplianceFrameworkPayload',
    },
  },
};

export const framework = {
  parsedId: 1,
  name: 'framework a',
  default: false,
  description: 'a framework',
  color: '#112233',
  editPath: 'group/framework/1/edit',
};

export const defaultFramework = {
  parsedId: 2,
  name: 'framework b',
  default: true,
  description: 'b framework',
  color: '#00b140',
  editPath: 'group/framework/2/edit',
};
