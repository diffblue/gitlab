# frozen_string_literal: true

# LDAP connection adapter EE mixin
#
# This module is intended to encapsulate EE-specific adapter methods
# and be **prepended** in the `Gitlab::Auth::Ldap::Adapter` class.
module EE
  module Gitlab
    module Auth
      module Ldap
        module Adapter
          # Get LDAP groups from ou=Groups
          #
          # cn - filter groups by name
          #
          # Ex.
          #   groups("dev*") # return all groups start with 'dev'
          #
          def groups(cn = "*", size = nil)
            options = {
              base: config.group_base,
              filter: Net::LDAP::Filter.eq("cn", cn),
              attributes: %w[dn cn memberuid member submember uniquemember memberof]
            }

            options[:size] = size if size

            ldap_search(options).map do |entry|
              Ldap::Group.new(entry, self)
            end
          end

          def group(...)
            groups(...).first
          end

          def group_members_in_range(dn, range_start)
            ldap_search(
              base: dn,
              scope: Net::LDAP::SearchScope_BaseObject,
              attributes: ["member;range=#{range_start}-*"]
            ).first
          end

          def nested_groups(parent_dn)
            options = {
              base: config.group_base,
              filter: Net::LDAP::Filter.join(
                Net::LDAP::Filter.eq('objectClass', 'group'),
                Net::LDAP::Filter.eq('memberOf', parent_dn)
              )
            }

            ldap_search(options).map do |entry|
              Ldap::Group.new(entry, self)
            end
          end

          def filter_search(filter)
            ldap_search(
              base: config.base,
              filter: Net::LDAP::Filter.construct(filter)
            )
          end

          def user_by_certificate_assertion(certificate_assertion)
            options = user_options_for_cert(certificate_assertion)
            users_search(options).first
          end

          private

          def user_options_for_cert(certificate_assertion)
            options = {
              attributes: ::Gitlab::Auth::Ldap::Person.ldap_attributes(config),
              base: config.base
            }

            filter = Net::LDAP::Filter.ex(
              'userCertificate:certificateExactMatch', certificate_assertion)

            options.merge(filter: user_filter(filter))
          end
        end
      end
    end
  end
end
