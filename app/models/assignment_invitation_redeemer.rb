class AssignmentInvitationRedeemer
  def initialize(assignment, invitee)
    @assignment         = assignment
    @invitee            = invitee
    @organization       = assignment.organization
    @organization_owner = find_organization_owner
  end

  def redeemed?
    repo_access     = find_or_create_repo_access
    assignment_repo = find_or_create_assignment_repo(repo_access)

    full_repo_name  = @organization_owner.github_client.repository(assignment_repo.github_repo_id).full_name
    @organization_owner.github_client.team_repository?(repo_access.github_team_id, full_repo_name)
  end

  protected

  def find_organization_owner
    @organization.users.find do |user|
      user.github_client.organization_admin?(@organization.github_id)
    end
  end

  private

  def create_assignment_repo(repo_access, assignment_name)
    org_login = @organization_owner.github_client.organization(@organization.github_id).login

    repo = GitHubRepository.create_repository(@organization_owner,
                                              assignment_name,
                                              organization: org_login,
                                              team_id:      repo_access.github_team_id,
                                              private:      @assignment.private?)

    assignment_repo = AssignmentRepo.new(assignment: @assignment, github_repo_id: repo.id, repo_access: repo_access)

    assignment_repo.save!
    assignment_repo
  end

  def create_repo_access(team_name)
    github_team = GitHubTeam.create_team(@organization_owner, @organization.github_id, team_name)

    github_team.add_user_to_team(@invitee)

    repo_access = RepoAccess.new(github_team_id: github_team.id, organization: @organization, user: @invitee)

    repo_access.save!
    repo_access
  end

  def find_assignment_repo(repo_access)
    @assignment.assignment_repos.find_by(repo_access: repo_access)
  end

  def find_or_create_assignment_repo(repo_access)
    if (assignment_repo = find_assignment_repo(repo_access))
      assignment_repo
    else
      assignment_name = "#{@assignment.title}: #{@assignment.assignment_repos.count + 1}"
      create_assignment_repo(repo_access, assignment_name)
    end
  end

  def find_or_create_repo_access
    if (repo_access = find_repo_access)
      repo_access
    else
      team_name = "Team: #{@organization.repo_accesses.count + 1}"
      create_repo_access(team_name)
    end
  end

  def find_repo_access
    @invitee.repo_accesses.find_by(organization: @organization)
  end
end
