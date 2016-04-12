class AssignmentRepo < ActiveRecord::Base
  include GitHubPlan
  include GitHubRepoable

  update_index('stafftools#assignment_repo') { self }

  has_one :organization, -> { unscope(where: :deleted_at) }, through: :assignment

  belongs_to :assignment
  belongs_to :repo_access
  belongs_to :user

  validates :assignment, presence: true

  validates :github_repo_id, presence:   true
  validates :github_repo_id, uniqueness: true

  before_validation(on: :create) do
    if organization
      create_github_repository
      push_starter_code
      add_user_as_collaborator
    end
  end

  before_destroy :silently_destroy_github_repository

  delegate :creator, :starter_code_repo_id, :starter_code?, to: :assignment
  delegate :github_user,                                    to: :user

  def disabled?
    return @disabled if @disabled
    @disabled = (github_repository.disabled? || github_user.disabled?)
  end

  def github_team_id
    repo_access.present? ? repo_access.github_team_id : nil
  end

  def private?
    !assignment.public_repo?
  end

  def repo_name
    "#{assignment.slug}-#{github_user.login(headers: GitHub::APIHeaders.no_cache_no_store)}"
  end

  # Public: This method is used for legacy purposes
  # until we can get the transition finally completed
  #
  # We used to create one person teams for Assignments,
  # however when the new organization permissions came out
  # https://github.com/blog/2020-improved-organization-permissions
  # we were able to move these students over to being an outside collaborator
  # so when we deleted the AssignmentRepo we would remove the student as well.
  #
  # Returns the User associated with the AssignmentRepo
  alias original_user user
  def user
    original_user || repo_access.user
  end
end
