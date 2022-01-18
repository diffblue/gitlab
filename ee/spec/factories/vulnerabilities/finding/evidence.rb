# frozen_string_literal: true

FactoryBot.define do
  factory :vulnerabilties_finding_evidence, class: 'Vulnerabilities::Finding::Evidence' do
    finding { association :vulnerabilities_finding }
    data do
      {
        summary: 'Credit card detected',
        request: {
          headers: [{ name: 'Accept', value: '*/*' }],
          method: 'GET',
          url: 'http://goat:8080/WebGoat/logout',
          body: nil
        },
        response: {
          headers: [{ name: 'Content-Length', value: '0' }],
          reason_phrase: 'OK',
          status_code: 200,
          body: nil
        },
        source: {
          id: 'assert:Response Body Analysis',
          name: 'Response Body Analysis',
          url: 'htpp://hostname/documentation'
        },
        supporting_messages: [
          {
            name: 'Origional',
            request: {
              headers: [{ name: 'Accept', value: '*/*' }],
              method: 'GET',
              url: 'http://goat:8080/WebGoat/logout',
              body: ''
            }
          },
          {
            name: 'Recorded',
            request: {
              headers: [{ name: 'Accept', value: '*/*' }],
              method: 'GET',
              url: 'http://goat:8080/WebGoat/logout',
              body: ''
            },
            response: {
              headers: [{ name: 'Content-Length', value: '0' }],
              reason_phrase: 'OK',
              status_code: 200,
              body: ''
            }
          }
        ]
      }
    end
  end
end
