# frozen_string_literal: true
class GitHubOrganization < GitHubResource
  def accept_membership(user_github_login)
    return if organization_member?(user_github_login)

    GitHub::Errors.with_error_handling do
      @client.update_organization_membership(login, state: 'active')
    end
  end

  def add_membership(user_github_login)
    return if organization_member?(user_github_login)

    GitHub::Errors.with_error_handling do
      @client.update_organization_membership(login, user: user_github_login)
    end
  end

  def admin?(user_github_login)
    GitHub::Errors.with_error_handling do
      membership = @client.organization_membership(login, user: user_github_login)
      membership.role == 'admin' && membership.state == 'active'
    end
  end

  # Public
  #
  def create_org_hook(config: {}, options: {})
    GitHub::Errors.with_error_handling do
      hook_config = github_hook_default_config.merge(config)
                                              .tap { |hash| hash[:secret] = ENV['WEBHOOK_SECRET'] }
      hook_options = github_hook_default_options.merge(options)
      @client.create_org_hook(@id, hook_config, hook_options)
    end
  end

  # Public
  #
  def delete_all_org_hooks
    GitHub::Errors.with_error_handling do
      hooks = @client.org_hooks(@id)
      hooks.each { |hook| @client.remove_org_hook(@id, hook.id) }
    end
  rescue GitHub::NotFound
    return
  end

  # Public
  #
  def create_repository(repo_name, users_repo_options = {})
    repo_options = github_repo_default_options.merge(users_repo_options)

    repo = GitHub::Errors.with_error_handling do
      @client.create_repository(repo_name, repo_options)
    end

    GitHubRepository.new(@client, repo.id)
  end

  def delete_repository(repo_id)
    @client.delete_repository(repo_id)
  end

  def create_team(team_name)
    github_team = GitHub::Errors.with_error_handling do
      @client.create_team(@id,
                          description: "#{team_name} created by GitHub Classroom",
                          name: team_name,
                          permission: 'push')
    end

    GitHubTeam.new(@client, github_team.id)
  end

  def delete_team(team_id)
    @client.delete_team(team_id)
  end

  def geo_pattern_data_uri
    @geo_pattern_data_uri ||= GeoPattern.generate(id, color: '#5fb27b').to_data_uri
  end

  def github_avatar_url(size = 40)
    "#{avatar_url}&size=#{size}"
  end

  def organization_members(options = {})
    GitHub::Errors.with_error_handling { @client.organization_members(@id, options) }
  end

  def organization_member?(user_github_login)
    GitHub::Errors.with_error_handling { @client.organization_member?(@id, user_github_login) }
  end

  def plan
    GitHub::Errors.with_error_handling do
      organization = @client.organization(@id, headers: GitHub::APIHeaders.no_cache_no_store)

      if organization.owned_private_repos.present? && organization.plan.present?
        { owned_private_repos: organization.owned_private_repos, private_repos: organization.plan.private_repos }
      else
        raise GitHub::Error, 'Cannot retrieve this organizations repo plan, please reauthenticate your token.'
      end
    end
  end

  def remove_organization_member(github_user_id)
    github_user_login = GitHubUser.new(@client, github_user_id).login

    begin
      return if admin?(github_user_login)
    rescue GitHub::NotFound
      return
    end

    GitHub::Errors.with_error_handling do
      @client.remove_organization_member(@id, github_user_login)
    end
  end

  def team_invitations_url
    "https://github.com/orgs/#{login}/invitations/new"
  end

  private

  # Internal
  #
  def github_hook_default_config
    {
      content_type: 'json'
    }
  end

  # Internal
  #
  def github_hook_default_options
    {
      events: %w(push),
      active: true
    }
  end

  # Internal
  #
  def attributes
    %w(login avatar_url html_url name)
  end

  def github_repo_default_options
    {
      has_issues:    true,
      has_wiki:      true,
      has_downloads: true,
      organization:  @id
    }
  end
end
