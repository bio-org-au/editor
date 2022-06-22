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

  def users_groups
    @groups
  end

  # Users full name.
  def user_full_name
    Rails.logger.info("Ldap#user_full_name")
    Ldap.new.admin_search(Rails.configuration.ldap_users,
                          "uid",
                          username,
                          "cn").first || username
  rescue => e
    Rails.logger.error("Error in Ldap#user_full_name for username: #{username}")
    Rails.logger.error(e.to_s)
    return username
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
    @active_directory_user || false
  end

  def openldap_user
    @openldap_user || false
  end

  # Known groups
  def self.groups
    Ldap.new.admin_search(Rails.configuration.ldap_groups,
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
    if Rails.configuration.try('ldap_via_active_directory')
      change_password_active_directory(uid,new_password,salt)
    else
      change_password_openldap(uid,new_password,salt)
    end
  end

  def change_password_openldap(uid,new_password,salt)
    conn = admin_connection
    digest = Digest::SHA1.digest("#{new_password}#{salt}")
    person = conn.search(base: Rails.configuration.ldap_users, filter: Net::LDAP::Filter.eq("uid",uid))
    new_hashed_password = "{SSHA}"+Base64.encode64(digest+salt).chomp!
    conn.replace_attribute(person.first.dn, 'userPassword', new_hashed_password)
  end

  def verify_current_password
    validate_user_credentials
  end

  def admin_connection
    if Rails.configuration.try('ldap_via_active_directory')
      admin_connection_active_directory
    else
      admin_connection_openldap
    end
  end

  def admin_connection_openldap
    Rails.logger.info("Connecting to LDAP")
    ldap = Net::LDAP.new
    Rails.logger.info("Rails.configuration.ldap_host: #{Rails.configuration.ldap_host}")
    Rails.logger.info("Rails.configuration.ldap_port: #{Rails.configuration.ldap_port}")
    Rails.logger.info("Rails.configuration.ldap_admin_username: #{Rails.configuration.ldap_admin_username}")
    ldap.port = Rails.configuration.ldap_port
    ldap.host = Rails.configuration.ldap_host
    ldap.auth Rails.configuration.ldap_admin_username,
              Rails.configuration.ldap_admin_password
    unless ldap.bind
      Rails.logger.error("LDAP error: #{ldap.get_operation_result.error_message}")
      raise "Failed admin connection!"
    end
    Rails.logger.info("Admin connection to LDAP succeeded")
    ldap
  end

  def admin_connection_active_directory
    Rails.logger.info("Connecting to Active Directory")
    Rails.logger.info("ldap_host: #{Rails.configuration.ldap_host}")
    Rails.logger.info("ldap_port: #{Rails.configuration.ldap_port}")
    Rails.logger.info("ldap_admin_username: #{Rails.configuration.ldap_admin_username}")
    ldap = Net::LDAP.new  :host => Rails.configuration.ldap_host,
                      :port => Rails.configuration.ldap_port,
                      :base => Rails.configuration.ldap_base,
                      :encryption => {:method => :simple_tls,
                                      :tls_options => { :verify_mode => OpenSSL::SSL::VERIFY_NONE }
                              },
                      :auth => {
                        :method => :simple,
                        :username => Rails.configuration.ldap_admin_username,
                        :password => Rails.configuration.ldap_admin_password
                      }
    unless ldap.bind
      Rails.logger.error("LDAP error: #{ldap.get_operation_result.error_message}")
      raise "Failed admin connection!"
    end
    Rails.logger.info("Admin connection to LDAP succeeded")
    ldap
  end

  private

  def validate_user_credentials
    if Rails.configuration.try('ldap_via_active_directory')
      validate_via_active_directory
    else
      validate_via_ldap
    end
  end

  def validate_via_active_directory
    bind_as = admin_connection.bind_as(
      base: Rails.configuration.ldap_users,
      filter: Net::LDAP::Filter.eq('samAccountName', username),
      password: password
    )
    if bind_as
      @display_name = bind_as.first[:displayname].first
      @groups = bind_as.first[:memberof].select {|x| x.match(/#{Rails.configuration.group_filter_regex}/i)}.collect {|x| x.split(',').first.split('=').last}
      @user_cn = bind_as.first[:dn].first
      @active_directory_user = true
      @openldap_user = false
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

  def validate_generic_user_in_active_directory
    bind_as = admin_connection.bind_as(
      base: Rails.configuration.ldap_generic_users,
      filter: Net::LDAP::Filter.eq('samAccountName', username),
      password: password
    )
    if bind_as
      @display_name = bind_as.first[:displayname].first
      @groups = bind_as.first[:memberof].select {|x| x.match(/#{Rails.configuration.group_filter_regex}/i)}.collect {|x| x.split(',').first.split('=').last}
      @user_cn = bind_as.first[:dn].first
      @active_directory_user = true
      @openldap_user = false
      @generic_active_directory_user = true
      return true
    else
      errors.add(:connection, "failed")
      Rails.logger.error("Validating alt user credentials failed for username: #{username} against AD samAccountName.")
      return false
    end
  rescue => e
    Rails.logger.error("Exception in validate_generic_user_credentials")
    Rails.logger.error(e.to_s)
    errors.add(:connection, "connection failed with exception")
  end
  
  def validate_via_ldap
    result = admin_connection.bind_as(
      base: Rails.configuration.ldap_users,
      filter: Net::LDAP::Filter.eq('uid', username),
      password: password
    )
    if result
      @display_name = ldap_full_name(result)
      @groups = ldap_user_groups
      @user_cn = 'not needed for openldap'
      @openldap_user = true
      @active_directory_user = false
      @generic_active_directory_user = false
      return true
    else
      errors.add(:connection, "failed")
      Rails.logger.error("Validating user credentials failed for username: #{username} against LDAP uid.")
      return false
    end
  rescue => e
    Rails.logger.error("Exception in validate_user_credentials")
    Rails.logger.error(e.to_s)
    errors.add(:connection, "connection failed with exception")
  end

  def ldap_full_name(result)
    result.first[:dn].first.split(',').select {|x| x =~ /cn=/}.first.split('=').second
  rescue => e
    Rails.logger.error("Error getting user full_name from LDAP")
    Rails.logger.error(e.to_s)
    return username
  end

  # Groups user is assigned to.
  def ldap_user_groups
    Rails.logger.info("Ldap#users_groups:" + Rails.configuration.ldap_groups)
    Ldap.new.admin_search(Rails.configuration.ldap_groups,
                          "uniqueMember",
                          "uid=#{username}", "cn")
  rescue => e
    Rails.logger.error("Error in Ldap#users_groups for username: #{username}")
    Rails.logger.error(e.to_s)
    return ["error getting groups"]
  end

  def change_password_active_directory(uid,new_password,salt)
    conn = admin_connection
    ops = [ [ :replace, :unicodePwd, unicode_password(new_password) ] ]
    Rails.logger.debug("ops: #{ops.inspect}")
    person = conn.search(base: Rails.configuration.ldap_users, filter: Net::LDAP::Filter.eq("samAccountName",uid))
    Rails.logger.debug("person.first.dn: #{person.first.dn}")
    if conn.replace_attribute(person.first.dn, 'unicodePwd', unicode_password(new_password))
      Rails.logger.debug('password changed!')
    else
      Rails.logger.error('password NOT changed!')
      Rails.logger.error(conn.get_operation_result.error_message)
      raise "#{conn.get_operation_result.error_message}"
    end
  end

  def unicode_password(clear_text_password)
    unicode_string = ""
    quoted_text = '"' + clear_text_password + '"'
    quoted_text.length.times{|i| unicode_string+= "#{quoted_text[i..i]}\000" }
    return unicode_string
  end
end
