class GitHubOrganization
  include GitHub

  attr_reader :login

  def initialize(client, id)
    @client    = client
    @id        = id
  end

  # Public
  #
  def create_repository(repo_name, users_repo_options = {})
    repo_options = github_repo_default_options.merge(users_repo_options)

    repo = with_error_handling do
      @client.create_repository(repo_name, repo_options)
    end

    GitHubRepository.new(@client, repo.id)
  end

  # Public
  #
  def create_team(team_name)
    github_team = with_error_handling do
      @client.create_team(@id, name: team_name, permission: 'push')
    end

    GitHubTeam.new(@client, github_team.id)
  end

  # Public
  #
  def login
    @login ||= with_error_handling { @client.organization(@id).login }
  end

  # Public
  #
  def authorization_on_github_organization?(organization_login)
    with_error_handling do
      if @client.organization_membership(organization_login).role != 'admin'
        fail GitHub::Forbidden
      end
    end
  end

  # Internal
  #
  def github_repo_default_options
    {
      has_issues:    true,
      has_wiki:      true,
      has_downloads: true,
      organization:  @id
    }
  end
end
