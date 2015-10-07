class User < ActiveRecord::Base
  include GitHub

  has_many :repo_accesses,    dependent: :destroy
  has_many :assignment_repos, through: :repo_accesses

  has_and_belongs_to_many :organizations

  validates :token, presence: true, uniqueness: true

  validates :uid, presence: true
  validates :uid, uniqueness: true

  # Public: Create a new User from an OAuth hash
  #
  # hash - The Omniauth OAuth hash to create the User from
  #
  # Returns whether or not the User was created
  def self.create_from_auth_hash(hash)
    create!(AuthHash.new(hash).user_info)
  end

  # Public: Update a Users attributes from an OAuth hash
  #
  # hash - The Omniauth OAuth hash to create the User from
  #
  # Returns
  def assign_from_auth_hash(hash)
    user_attributes = AuthHash.new(hash).user_info
    update_attributes(user_attributes)
  end

  # Public: Find the User from the given OAuth hash
  #
  # hash - The Omniauth OAuth hash to find the User
  #
  # Returns: The found User Activerecord object
  def self.find_by_auth_hash(hash)
    conditions = AuthHash.new(hash).user_info.slice(:uid)
    find_by(conditions)
  end

  # Public: Get users GitHubClient or set a new one with
  # their personal access token
  #
  # Returns The Users GitHubClient
  def github_client
    @github_client ||= Octokit::Client.new(access_token: token, auto_paginate: true)
  end

  # Public: Determine if the User is a site_admin
  # Returns site_admin
  def staff?
    site_admin
  end

  def valid_auth_token?
    required_scopes = %w(admin:org delete_repo repo user:email)
    (required_scopes - github_client.scopes(token, headers: no_cache_headers)).empty? ? true : false
  rescue Octokit::NotFound, Octokit::Unauthorized
    false
  end
end
