export const apiFuzzingConfigurationQueryResponse = {
  data: {
    project: {
      id: '1',
      apiFuzzingCiConfiguration: {
        scanModes: ['HAR', 'OPENAPI'],
        scanProfiles: [
          {
            name: 'Quick-10',
            description: 'Fuzzing 10 times per parameter',
            yaml:
              '---\nName: Quick-10\nDefaultProfile: Empty\nRoutes:\n- Route:\n    Order: 0\n    Url: "**"\n    Mutate: true\n    SwaggerUrl:\n    Script:\n    Headers:\n    - Pattern: Host\n      Mutate: false\n    - Pattern: Connection\n      Mutate: false\n    - Pattern: Content-Length\n      Mutate: false\n    ApiTokens:\n    - Name: Authorization\n      Where: Header\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: access_token\n      Where: FormData\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: access_token\n      Where: Query\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: X-API-Key\n      Where: Header\n      Expiration: 120\n      IsSignatureOfRequest: false\n  Checks:\n  - Name: FormBodyFuzzingCheck\n    Configuration:\n      FuzzingCount: 10\n      UnicodeFuzzing: true\n  - Name: GeneralFuzzingCheck\n    Configuration:\n      FuzzingCount: 10\n      UnicodeFuzzing: true\n      HeaderFuzzing: false\n      Headers:\n  - Name: JsonFuzzingCheck\n    Configuration:\n      FuzzingCount: 10\n      UnicodeFuzzing: true\n  - Name: XmlFuzzingCheck\n    Configuration:\n      FuzzingCount: 10\n      UnicodeFuzzing: true\n',
            __typename: 'ApiFuzzingScanProfile',
          },
          {
            name: 'Medium-20',
            description: 'Fuzzing 20 times per parameter',
            yaml:
              '---\nName: Medium-20\nDefaultProfile: Empty\nRoutes:\n- Route:\n    Order: 0\n    Url: "**"\n    Mutate: true\n    SwaggerUrl:\n    Script:\n    Headers:\n    - Pattern: Host\n      Mutate: false\n    - Pattern: Connection\n      Mutate: false\n    - Pattern: Content-Length\n      Mutate: false\n    ApiTokens:\n    - Name: Authorization\n      Where: Header\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: access_token\n      Where: FormData\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: access_token\n      Where: Query\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: X-API-Key\n      Where: Header\n      Expiration: 120\n      IsSignatureOfRequest: false\n  Checks:\n  - Name: FormBodyFuzzingCheck\n    Configuration:\n      FuzzingCount: 20\n      UnicodeFuzzing: true\n  - Name: GeneralFuzzingCheck\n    Configuration:\n      FuzzingCount: 20\n      UnicodeFuzzing: true\n      HeaderFuzzing: false\n      Headers:\n  - Name: JsonFuzzingCheck\n    Configuration:\n      FuzzingCount: 20\n      UnicodeFuzzing: true\n  - Name: XmlFuzzingCheck\n    Configuration:\n      FuzzingCount: 20\n      UnicodeFuzzing: true\n',
            __typename: 'ApiFuzzingScanProfile',
          },
          {
            name: 'Medium-50',
            description: 'Fuzzing 50 times per parameter',
            yaml:
              '---\nName: Medium-50\nDefaultProfile: Empty\nRoutes:\n- Route:\n    Order: 0\n    Url: "**"\n    Mutate: true\n    SwaggerUrl:\n    Script:\n    Headers:\n    - Pattern: Host\n      Mutate: false\n    - Pattern: Connection\n      Mutate: false\n    - Pattern: Content-Length\n      Mutate: false\n    ApiTokens:\n    - Name: Authorization\n      Where: Header\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: access_token\n      Where: FormData\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: access_token\n      Where: Query\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: X-API-Key\n      Where: Header\n      Expiration: 120\n      IsSignatureOfRequest: false\n  Checks:\n  - Name: FormBodyFuzzingCheck\n    Configuration:\n      FuzzingCount: 50\n      UnicodeFuzzing: true\n  - Name: GeneralFuzzingCheck\n    Configuration:\n      FuzzingCount: 50\n      UnicodeFuzzing: true\n      HeaderFuzzing: false\n      Headers:\n  - Name: JsonFuzzingCheck\n    Configuration:\n      FuzzingCount: 50\n      UnicodeFuzzing: true\n  - Name: XmlFuzzingCheck\n    Configuration:\n      FuzzingCount: 50\n      UnicodeFuzzing: true\n',
            __typename: 'ApiFuzzingScanProfile',
          },
          {
            name: 'Long-100',
            description: 'Fuzzing 100 times per parameter',
            yaml:
              '---\nName: Long-100\nDefaultProfile: Empty\nRoutes:\n- Route:\n    Order: 0\n    Url: "**"\n    Mutate: true\n    SwaggerUrl:\n    Script:\n    Headers:\n    - Pattern: Host\n      Mutate: false\n    - Pattern: Connection\n      Mutate: false\n    - Pattern: Content-Length\n      Mutate: false\n    ApiTokens:\n    - Name: Authorization\n      Where: Header\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: access_token\n      Where: FormData\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: access_token\n      Where: Query\n      Expiration: 120\n      IsSignatureOfRequest: false\n    - Name: X-API-Key\n      Where: Header\n      Expiration: 120\n      IsSignatureOfRequest: false\n  Checks:\n  - Name: FormBodyFuzzingCheck\n    Configuration:\n      FuzzingCount: 100\n      UnicodeFuzzing: true\n  - Name: GeneralFuzzingCheck\n    Configuration:\n      FuzzingCount: 100\n      UnicodeFuzzing: true\n      HeaderFuzzing: false\n      Headers:\n  - Name: JsonFuzzingCheck\n    Configuration:\n      FuzzingCount: 100\n      UnicodeFuzzing: true\n  - Name: XmlFuzzingCheck\n    Configuration:\n      FuzzingCount: 100\n      UnicodeFuzzing: true\n',
            __typename: 'ApiFuzzingScanProfile',
          },
        ],
        __typename: 'ApiFuzzingCiConfiguration',
      },
      __typename: 'Project',
    },
  },
};
