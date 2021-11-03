import mockGetCodeQualityViolationsResponse from 'test_fixtures/graphql/codequality_report/graphql/queries/get_code_quality_violations.query.graphql.json';

export { mockGetCodeQualityViolationsResponse };

export const codeQualityViolations =
  mockGetCodeQualityViolationsResponse.data.project.pipeline.codeQualityReports;

export const unparsedIssues = [
  {
    type: 'issue',
    check_name: 'similar-code',
    description: 'Similar blocks of code found in 2 locations. Consider refactoring.',
    categories: ['Duplication'],
    location: {
      path: 'ee/spec/features/admin/geo/admin_geo_projects_spec.rb',
      lines: {
        begin: 152,
        end: 158,
      },
    },
    remediation_points: 230000,
    other_locations: [
      {
        path: 'ee/spec/features/admin/geo/admin_geo_projects_spec.rb',
        lines: {
          begin: 134,
          end: 140,
        },
      },
    ],
    content: {
      body:
        "## Duplicated Code\n\nDuplicated code can lead to software that is hard to understand and difficult to change. The Don't Repeat Yourself (DRY) principle states:\n\n> Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.\n\nWhen you violate DRY, bugs and maintenance problems are sure to follow. Duplicated code has a tendency to both continue to replicate and also to diverge (leaving bugs as two similar implementations differ in subtle ways).\n\n## Tuning\n\n**This issue has a mass of 29**.\n\nWe set useful threshold defaults for the languages we support but you may want to adjust these settings based on your project guidelines.\n\nThe threshold configuration represents the minimum [mass](https://docs.codeclimate.com/docs/duplication#mass) a code block must have to be analyzed for duplication. The lower the threshold, the more fine-grained the comparison.\n\nIf the engine is too easily reporting duplication, try raising the threshold. If you suspect that the engine isn't catching enough duplication, try lowering the threshold. The best setting tends to differ from language to language.\n\nSee [`codeclimate-duplication`'s documentation](https://docs.codeclimate.com/docs/duplication) for more information about tuning the mass threshold in your `.codeclimate.yml`.\n\n## Refactorings\n\n*   [Extract Method](http://sourcemaking.com/refactoring/extract-method)\n*   [Extract Class](http://sourcemaking.com/refactoring/extract-class)\n*   [Form Template Method](http://sourcemaking.com/refactoring/form-template-method)\n*   [Introduce Null Object](http://sourcemaking.com/refactoring/introduce-null-object)\n*   [Pull Up Method](http://sourcemaking.com/refactoring/pull-up-method)\n*   [Pull Up Field](http://sourcemaking.com/refactoring/pull-up-field)\n*   [Substitute Algorithm](http://sourcemaking.com/refactoring/substitute-algorithm)\n\n## Further Reading\n\n*   [Don't Repeat Yourself](http://c2.com/cgi/wiki?DontRepeatYourself) on the C2 Wiki\n*   [Duplicated Code](http://sourcemaking.com/refactoring/duplicated-code) on SourceMaking\n*   [Refactoring: Improving the Design of Existing Code](http://www.amazon.com/Refactoring-Improving-Design-Existing-Code/dp/0201485672) by Martin Fowler. _Duplicated Code_, p76\n",
    },
    fingerprint: 'eee6e62c2e1e0eaf901e747c935a7c63',
    severity: 'minor',
    engine_name: 'duplication',
  },
  {
    type: 'issue',
    check_name: 'similar-code',
    description: 'Similar blocks of code found in 2 locations. Consider refactoring.',
    categories: ['Duplication'],
    location: {
      path: 'ee/spec/finders/geo/lfs_object_registry_finder_spec.rb',
      lines: {
        begin: 491,
        end: 497,
      },
    },
    remediation_points: 230000,
    other_locations: [
      {
        path: 'ee/spec/finders/geo/lfs_object_registry_finder_spec.rb',
        lines: {
          begin: 512,
          end: 518,
        },
      },
    ],
    content: {
      body:
        "## Duplicated Code\n\nDuplicated code can lead to software that is hard to understand and difficult to change. The Don't Repeat Yourself (DRY) principle states:\n\n> Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.\n\nWhen you violate DRY, bugs and maintenance problems are sure to follow. Duplicated code has a tendency to both continue to replicate and also to diverge (leaving bugs as two similar implementations differ in subtle ways).\n\n## Tuning\n\n**This issue has a mass of 29**.\n\nWe set useful threshold defaults for the languages we support but you may want to adjust these settings based on your project guidelines.\n\nThe threshold configuration represents the minimum [mass](https://docs.codeclimate.com/docs/duplication#mass) a code block must have to be analyzed for duplication. The lower the threshold, the more fine-grained the comparison.\n\nIf the engine is too easily reporting duplication, try raising the threshold. If you suspect that the engine isn't catching enough duplication, try lowering the threshold. The best setting tends to differ from language to language.\n\nSee [`codeclimate-duplication`'s documentation](https://docs.codeclimate.com/docs/duplication) for more information about tuning the mass threshold in your `.codeclimate.yml`.\n\n## Refactorings\n\n*   [Extract Method](http://sourcemaking.com/refactoring/extract-method)\n*   [Extract Class](http://sourcemaking.com/refactoring/extract-class)\n*   [Form Template Method](http://sourcemaking.com/refactoring/form-template-method)\n*   [Introduce Null Object](http://sourcemaking.com/refactoring/introduce-null-object)\n*   [Pull Up Method](http://sourcemaking.com/refactoring/pull-up-method)\n*   [Pull Up Field](http://sourcemaking.com/refactoring/pull-up-field)\n*   [Substitute Algorithm](http://sourcemaking.com/refactoring/substitute-algorithm)\n\n## Further Reading\n\n*   [Don't Repeat Yourself](http://c2.com/cgi/wiki?DontRepeatYourself) on the C2 Wiki\n*   [Duplicated Code](http://sourcemaking.com/refactoring/duplicated-code) on SourceMaking\n*   [Refactoring: Improving the Design of Existing Code](http://www.amazon.com/Refactoring-Improving-Design-Existing-Code/dp/0201485672) by Martin Fowler. _Duplicated Code_, p76\n",
    },
    fingerprint: '60d0dd59a1cd7e6da18fdeb6c7fdd17f',
    severity: 'minor',
    engine_name: 'duplication',
  },
  {
    type: 'issue',
    check_name: 'similar-code',
    description: 'Similar blocks of code found in 2 locations. Consider refactoring.',
    categories: ['Duplication'],
    location: {
      path: 'ee/spec/finders/geo/lfs_object_registry_finder_spec.rb',
      lines: {
        begin: 512,
        end: 518,
      },
    },
    remediation_points: 230000,
    other_locations: [
      {
        path: 'ee/spec/finders/geo/lfs_object_registry_finder_spec.rb',
        lines: {
          begin: 491,
          end: 497,
        },
      },
    ],
    content: {
      body:
        "## Duplicated Code\n\nDuplicated code can lead to software that is hard to understand and difficult to change. The Don't Repeat Yourself (DRY) principle states:\n\n> Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.\n\nWhen you violate DRY, bugs and maintenance problems are sure to follow. Duplicated code has a tendency to both continue to replicate and also to diverge (leaving bugs as two similar implementations differ in subtle ways).\n\n## Tuning\n\n**This issue has a mass of 29**.\n\nWe set useful threshold defaults for the languages we support but you may want to adjust these settings based on your project guidelines.\n\nThe threshold configuration represents the minimum [mass](https://docs.codeclimate.com/docs/duplication#mass) a code block must have to be analyzed for duplication. The lower the threshold, the more fine-grained the comparison.\n\nIf the engine is too easily reporting duplication, try raising the threshold. If you suspect that the engine isn't catching enough duplication, try lowering the threshold. The best setting tends to differ from language to language.\n\nSee [`codeclimate-duplication`'s documentation](https://docs.codeclimate.com/docs/duplication) for more information about tuning the mass threshold in your `.codeclimate.yml`.\n\n## Refactorings\n\n*   [Extract Method](http://sourcemaking.com/refactoring/extract-method)\n*   [Extract Class](http://sourcemaking.com/refactoring/extract-class)\n*   [Form Template Method](http://sourcemaking.com/refactoring/form-template-method)\n*   [Introduce Null Object](http://sourcemaking.com/refactoring/introduce-null-object)\n*   [Pull Up Method](http://sourcemaking.com/refactoring/pull-up-method)\n*   [Pull Up Field](http://sourcemaking.com/refactoring/pull-up-field)\n*   [Substitute Algorithm](http://sourcemaking.com/refactoring/substitute-algorithm)\n\n## Further Reading\n\n*   [Don't Repeat Yourself](http://c2.com/cgi/wiki?DontRepeatYourself) on the C2 Wiki\n*   [Duplicated Code](http://sourcemaking.com/refactoring/duplicated-code) on SourceMaking\n*   [Refactoring: Improving the Design of Existing Code](http://www.amazon.com/Refactoring-Improving-Design-Existing-Code/dp/0201485672) by Martin Fowler. _Duplicated Code_, p76\n",
    },
    fingerprint: '60d0dd59a1cd7e6da18fdeb6c7fdd17f',
    severity: 'minor',
    engine_name: 'duplication',
  },
];

export const parsedIssues = [
  {
    type: 'issue',
    check_name: 'similar-code',
    description: 'Similar blocks of code found in 2 locations. Consider refactoring.',
    categories: ['Duplication'],
    location: {
      path: 'ee/spec/features/admin/geo/admin_geo_projects_spec.rb',
      lines: { begin: 152, end: 158 },
    },
    remediation_points: 230000,
    other_locations: [
      {
        path: 'ee/spec/features/admin/geo/admin_geo_projects_spec.rb',
        lines: { begin: 134, end: 140 },
      },
    ],
    content: {
      body:
        "## Duplicated Code\n\nDuplicated code can lead to software that is hard to understand and difficult to change. The Don't Repeat Yourself (DRY) principle states:\n\n> Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.\n\nWhen you violate DRY, bugs and maintenance problems are sure to follow. Duplicated code has a tendency to both continue to replicate and also to diverge (leaving bugs as two similar implementations differ in subtle ways).\n\n## Tuning\n\n**This issue has a mass of 29**.\n\nWe set useful threshold defaults for the languages we support but you may want to adjust these settings based on your project guidelines.\n\nThe threshold configuration represents the minimum [mass](https://docs.codeclimate.com/docs/duplication#mass) a code block must have to be analyzed for duplication. The lower the threshold, the more fine-grained the comparison.\n\nIf the engine is too easily reporting duplication, try raising the threshold. If you suspect that the engine isn't catching enough duplication, try lowering the threshold. The best setting tends to differ from language to language.\n\nSee [`codeclimate-duplication`'s documentation](https://docs.codeclimate.com/docs/duplication) for more information about tuning the mass threshold in your `.codeclimate.yml`.\n\n## Refactorings\n\n*   [Extract Method](http://sourcemaking.com/refactoring/extract-method)\n*   [Extract Class](http://sourcemaking.com/refactoring/extract-class)\n*   [Form Template Method](http://sourcemaking.com/refactoring/form-template-method)\n*   [Introduce Null Object](http://sourcemaking.com/refactoring/introduce-null-object)\n*   [Pull Up Method](http://sourcemaking.com/refactoring/pull-up-method)\n*   [Pull Up Field](http://sourcemaking.com/refactoring/pull-up-field)\n*   [Substitute Algorithm](http://sourcemaking.com/refactoring/substitute-algorithm)\n\n## Further Reading\n\n*   [Don't Repeat Yourself](http://c2.com/cgi/wiki?DontRepeatYourself) on the C2 Wiki\n*   [Duplicated Code](http://sourcemaking.com/refactoring/duplicated-code) on SourceMaking\n*   [Refactoring: Improving the Design of Existing Code](http://www.amazon.com/Refactoring-Improving-Design-Existing-Code/dp/0201485672) by Martin Fowler. _Duplicated Code_, p76\n",
    },
    fingerprint: 'eee6e62c2e1e0eaf901e747c935a7c63',
    severity: 'minor',
    engine_name: 'duplication',
    name: 'Similar blocks of code found in 2 locations. Consider refactoring.',
    path: 'ee/spec/features/admin/geo/admin_geo_projects_spec.rb',
    line: 152,
    urlPath:
      '/root/test-codequality/blob/feature-branch/ee/spec/features/admin/geo/admin_geo_projects_spec.rb#L152',
  },
  {
    type: 'issue',
    check_name: 'similar-code',
    description: 'Similar blocks of code found in 2 locations. Consider refactoring.',
    categories: ['Duplication'],
    location: {
      path: 'ee/spec/finders/geo/lfs_object_registry_finder_spec.rb',
      lines: { begin: 491, end: 497 },
    },
    remediation_points: 230000,
    other_locations: [
      {
        path: 'ee/spec/finders/geo/lfs_object_registry_finder_spec.rb',
        lines: { begin: 512, end: 518 },
      },
    ],
    content: {
      body:
        "## Duplicated Code\n\nDuplicated code can lead to software that is hard to understand and difficult to change. The Don't Repeat Yourself (DRY) principle states:\n\n> Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.\n\nWhen you violate DRY, bugs and maintenance problems are sure to follow. Duplicated code has a tendency to both continue to replicate and also to diverge (leaving bugs as two similar implementations differ in subtle ways).\n\n## Tuning\n\n**This issue has a mass of 29**.\n\nWe set useful threshold defaults for the languages we support but you may want to adjust these settings based on your project guidelines.\n\nThe threshold configuration represents the minimum [mass](https://docs.codeclimate.com/docs/duplication#mass) a code block must have to be analyzed for duplication. The lower the threshold, the more fine-grained the comparison.\n\nIf the engine is too easily reporting duplication, try raising the threshold. If you suspect that the engine isn't catching enough duplication, try lowering the threshold. The best setting tends to differ from language to language.\n\nSee [`codeclimate-duplication`'s documentation](https://docs.codeclimate.com/docs/duplication) for more information about tuning the mass threshold in your `.codeclimate.yml`.\n\n## Refactorings\n\n*   [Extract Method](http://sourcemaking.com/refactoring/extract-method)\n*   [Extract Class](http://sourcemaking.com/refactoring/extract-class)\n*   [Form Template Method](http://sourcemaking.com/refactoring/form-template-method)\n*   [Introduce Null Object](http://sourcemaking.com/refactoring/introduce-null-object)\n*   [Pull Up Method](http://sourcemaking.com/refactoring/pull-up-method)\n*   [Pull Up Field](http://sourcemaking.com/refactoring/pull-up-field)\n*   [Substitute Algorithm](http://sourcemaking.com/refactoring/substitute-algorithm)\n\n## Further Reading\n\n*   [Don't Repeat Yourself](http://c2.com/cgi/wiki?DontRepeatYourself) on the C2 Wiki\n*   [Duplicated Code](http://sourcemaking.com/refactoring/duplicated-code) on SourceMaking\n*   [Refactoring: Improving the Design of Existing Code](http://www.amazon.com/Refactoring-Improving-Design-Existing-Code/dp/0201485672) by Martin Fowler. _Duplicated Code_, p76\n",
    },
    fingerprint: '60d0dd59a1cd7e6da18fdeb6c7fdd17f',
    severity: 'minor',
    engine_name: 'duplication',
    name: 'Similar blocks of code found in 2 locations. Consider refactoring.',
    path: 'ee/spec/finders/geo/lfs_object_registry_finder_spec.rb',
    line: 491,
    urlPath:
      '/root/test-codequality/blob/feature-branch/ee/spec/finders/geo/lfs_object_registry_finder_spec.rb#L491',
  },
  {
    type: 'issue',
    check_name: 'similar-code',
    description: 'Similar blocks of code found in 2 locations. Consider refactoring.',
    categories: ['Duplication'],
    location: {
      path: 'ee/spec/finders/geo/lfs_object_registry_finder_spec.rb',
      lines: { begin: 512, end: 518 },
    },
    remediation_points: 230000,
    other_locations: [
      {
        path: 'ee/spec/finders/geo/lfs_object_registry_finder_spec.rb',
        lines: { begin: 491, end: 497 },
      },
    ],
    content: {
      body:
        "## Duplicated Code\n\nDuplicated code can lead to software that is hard to understand and difficult to change. The Don't Repeat Yourself (DRY) principle states:\n\n> Every piece of knowledge must have a single, unambiguous, authoritative representation within a system.\n\nWhen you violate DRY, bugs and maintenance problems are sure to follow. Duplicated code has a tendency to both continue to replicate and also to diverge (leaving bugs as two similar implementations differ in subtle ways).\n\n## Tuning\n\n**This issue has a mass of 29**.\n\nWe set useful threshold defaults for the languages we support but you may want to adjust these settings based on your project guidelines.\n\nThe threshold configuration represents the minimum [mass](https://docs.codeclimate.com/docs/duplication#mass) a code block must have to be analyzed for duplication. The lower the threshold, the more fine-grained the comparison.\n\nIf the engine is too easily reporting duplication, try raising the threshold. If you suspect that the engine isn't catching enough duplication, try lowering the threshold. The best setting tends to differ from language to language.\n\nSee [`codeclimate-duplication`'s documentation](https://docs.codeclimate.com/docs/duplication) for more information about tuning the mass threshold in your `.codeclimate.yml`.\n\n## Refactorings\n\n*   [Extract Method](http://sourcemaking.com/refactoring/extract-method)\n*   [Extract Class](http://sourcemaking.com/refactoring/extract-class)\n*   [Form Template Method](http://sourcemaking.com/refactoring/form-template-method)\n*   [Introduce Null Object](http://sourcemaking.com/refactoring/introduce-null-object)\n*   [Pull Up Method](http://sourcemaking.com/refactoring/pull-up-method)\n*   [Pull Up Field](http://sourcemaking.com/refactoring/pull-up-field)\n*   [Substitute Algorithm](http://sourcemaking.com/refactoring/substitute-algorithm)\n\n## Further Reading\n\n*   [Don't Repeat Yourself](http://c2.com/cgi/wiki?DontRepeatYourself) on the C2 Wiki\n*   [Duplicated Code](http://sourcemaking.com/refactoring/duplicated-code) on SourceMaking\n*   [Refactoring: Improving the Design of Existing Code](http://www.amazon.com/Refactoring-Improving-Design-Existing-Code/dp/0201485672) by Martin Fowler. _Duplicated Code_, p76\n",
    },
    fingerprint: '60d0dd59a1cd7e6da18fdeb6c7fdd17f',
    severity: 'minor',
    engine_name: 'duplication',
    name: 'Similar blocks of code found in 2 locations. Consider refactoring.',
    path: 'ee/spec/finders/geo/lfs_object_registry_finder_spec.rb',
    line: 512,
    urlPath:
      '/root/test-codequality/blob/feature-branch/ee/spec/finders/geo/lfs_object_registry_finder_spec.rb#L512',
  },
];
