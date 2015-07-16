class GitHubTeam
  include GitHub

  attr_reader :id

  def initialize(client, id)
    @client = client
    @id     = id
  end

  # Public
  #
  def add_team_membership(new_user_github_login)
    with_error_handling do
      @client.add_team_membership(@id, new_user_github_login)
    end
  end

  # Publc
  #
  def add_team_repository(full_name)
    with_error_handling do
      unless @client.add_team_repository(@id, full_name)
        fail GitHub::Error, 'Could not add team to the GitHub repository'
      end
    end
  end

  # Public
  #
  def team_repository?(full_name)
    with_error_handling do
      @client.team_repository?(@id, full_name)
    end
  end
end
