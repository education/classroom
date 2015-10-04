class NullGitHubTeam < NullGitHubResource
  def name
    'Deleted team'
  end

  def organization
    NullGitHubOrganization.new
  end

  def slug
    'ghost'
  end
end
