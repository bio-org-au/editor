# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
class Ldap  < ActiveType::Object
  attribute :username, :string
  attribute :password, :string
  attribute :user_cn, :string

  validates :username, presence: true
  validates :password, presence: true

  validate :validate_user_credentials

  HOST = Rails.configuration.try('ldap_host')
  # e.g. ldap_host = "ldaps.biodiversity.org.au"
  PORT = Rails.configuration.try('ldap_port')
  BASE = Rails.configuration.try('ldap_base')
  # e.g. Rails.configuration.ldap_base = "ou=users,ou=nsl,dc=cloud,dc=biodiversity,dc=org,dc=au"
  GROUPS_PATH = Rails.configuration.try('ldap_groups')
  # e.g. ldap_groups = "ou=groups,cn=dev,dc=nsl,dc=bio,dc=org,dc=au"
  USERID_FIELD = Rails.configuration.try('ldap_userid_field') || 'samAccountName'
  # e.g. ldap_userid_field = "uid"            (openldap)
  # e.g. ldap_userid_field = "samAccountName" (active directory)
  VERIFY_CERT = Rails.configuration.try('ldap_verify_certificate')
  USERS = Rails.configuration.try('ldap_users')
  # e.g. ldap_users: "ou=users,ou=nsl,dc=cloud,dc=biodiversity,dc=org,dc=au"
  ADMIN_USERNAME = Rails.configuration.try('ldap_admin_username')
  # e.g. ldap_admin_username = "cn=NSL Admin,ou=users,ou=nsl,dc=cloud,dc=biodiversity,dc=org,dc=au"
  ADMIN_PASSWORD = Rails.configuration.try('ldap_admin_password')
  GENERIC_USERS = Rails.configuration.try('ldap_generic_users')
  # e.g. ldap_generic_users: "cn=Users,dc=cloud,dc=biodiversity,dc=org,dc=au"
  GROUP_FILTER_REGEX = Rails.configuration.try('ldap_group_filter_regex') 
  # Rails.configuration.group_filter_regex = 'ou=dev,ou=nsl'

  def users_groups
    @groups
  end

  def user_full_name
    @display_name || username
  end

  def user_cn
    @user_cn || 'unknown'
  end

  def generic_active_directory_user
    @generic_active_directory_user || false
  end

  def active_directory_user
    true
  end

  def openldap_user
    false
  end

  # Known groups
  def self.groups
    Ldap.new.admin_search(GROUPS_PATH,
                          "objectClass",
                          "groupOfUniqueNames",
                          "cn")
  end

  # Return an array of search results
  def admin_search(base, attribute, value, print_attribute)
    filter = Net::LDAP::Filter.eq(attribute, value)
    result = admin_connection.search(base: base,
                                     filter: filter).try("collect") do |entry|
      entry.send(print_attribute)
    end.try("flatten") || []
    if admin_connection.get_operation_result.error_message.present?
      raise admin_connection.get_operation_result.error_message
    end
    result
  end

  # See https://github.com/ruby-ldap/ruby-net-ldap/issues/290
  def change_password(uid,new_password,salt)
    conn = admin_connection
    ops = [ [ :replace, :unicodePwd, unicode_password(new_password) ] ]
    person = conn.search(base: USERS, filter: Net::LDAP::Filter.eq(USERID_FIELD,uid))
    if person.blank?
      person = conn.search(base: GENERIC_USERS, filter: Net::LDAP::Filter.eq(USERID_FIELD,uid))
    end
    Rails.logger.debug("person.first.dn: #{person.first.dn}")
    if conn.replace_attribute(person.first.dn, 'unicodePwd', unicode_password(new_password))
      Rails.logger.debug('password changed!')
    else
      Rails.logger.error('password NOT changed!')
      Rails.logger.error(conn.get_operation_result.error_message)
      raise "#{conn.get_operation_result.error_message}"
    end
  end

  def verify_current_password
    validate_user_credentials
  end

  def admin_connection
    Rails.logger.info("Connecting to Active Directory")
    ldap = Net::LDAP.new  :host => HOST,
        :port => PORT,
        :base => BASE,
        :encryption => {:method => :simple_tls,
                        :tls_options => tls_options },
        :auth => {
          :method => :simple,
          :username => ADMIN_USERNAME,
          :password => ADMIN_PASSWORD
        }
    unless ldap.bind
      Rails.logger.error("LDAP: #{ldap.get_operation_result.error_message}")
      raise "Failed admin connection!"
    end
    Rails.logger.info("Admin connection to AD succeeded")
    ldap
  end

  private

  # By default verify the certificate
  # Only if VERIFY_CERT is explicitly false do we avoid verifying cert
  # i.e. if nil or true we verify
  def tls_options
    case VERIFY_CERT
    when false
      { :verify_mode => OpenSSL::SSL::VERIFY_NONE }
    else
      # verify
      {}
    end
  end

  def validate_user_credentials
    bind_as = admin_connection.bind_as(
      base: USERS,
      filter: Net::LDAP::Filter.eq(USERID_FIELD, username),
      password: password
    )
    if bind_as
      set_bind_as_instance_variables(bind_as)
      @generic_active_directory_user = false
      return true
    else
      return validate_generic_user_in_active_directory
    end
  rescue => e
    Rails.logger.error("Exception in validate_user_credentials")
    Rails.logger.error(e.to_s)
    errors.add(:connection, "connection failed with exception")
  end

  def set_bind_as_instance_variables(bind_as)
    @display_name = bind_as.first[:displayname].first
    @groups = bind_as.first[:memberof].select {|x| x.match(/#{GROUP_FILTER_REGEX}/i)}.collect {|x| x.split(',').first.split('=').last}
    @user_cn = bind_as.first[:dn].first
  end

  def validate_generic_user_in_active_directory
    bind_as = admin_connection.bind_as(
      base: GENERIC_USERS,
      filter: Net::LDAP::Filter.eq(USERID_FIELD, username),
      password: password
    )
    if bind_as
      set_bind_as_instance_variables(bind_as)
      @generic_active_directory_user = true
      return true
    else
      errors.add(:connection, "failed")
      Rails.logger.error("Validating alt user credentials failed for username: #{username} against AD #{USERID_FIELD}.")
      return false
    end
  rescue => e
    Rails.logger.error("Exception in validate_generic_user_credentials")
    Rails.logger.error(e.to_s)
    errors.add(:connection, "connection failed with exception")
  end
  
  def ldap_full_name(result)
    result.first[:dn].first.split(',')
      .select {|x| x =~ /cn=/}.first.split('=').second
  rescue => e
    Rails.logger.error("Error getting user full_name from LDAP")
    Rails.logger.error(e.to_s)
    return username
  end

  # Groups user is assigned to.
  def ldap_user_groups
    Rails.logger.info("ldap_user_groups start; GROUPS_PATH: #{GROUPS_PATH}")
    Ldap.new.admin_search(GROUPS_PATH,
                          "uniqueMember",
                          "uid=#{username}", "cn")
  rescue => e
    Rails.logger.error("Error in Ldap#ldap_user_groups for username: #{username}")
    Rails.logger.error(e.to_s)
    return ["error getting groups"]
  end

  def unicode_password(clear_text_password)
    unicode_string = ""
    quoted_text = '"' + clear_text_password + '"'
    quoted_text.length.times{|i| unicode_string+= "#{quoted_text[i..i]}\000" }
    return unicode_string
  end
end
