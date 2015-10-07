class AssignmentInvitation < ActiveRecord::Base
  default_scope { where(deleted_at: nil) }

  has_one :organization, through: :assignment

  belongs_to :assignment

  validates :assignment, presence: true

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  # Public: Redeem invitation for a given User
  #
  # invitee - The User that is invited
  #
  # Returns the full name of the newly created GitHub repository
  def redeem_for(invitee)
    repo_access = RepoAccess.find_or_create_by!(user: invitee, organization: organization)
    AssignmentRepo.find_or_create_by!(assignment: assignment, repo_access: repo_access)
  end

  def title
    assignment.title
  end

  # Public: Override the AssignmentInvitation path so that it uses the key
  # instead of the id
  #
  # Returns the key as a String
  def to_param
    key
  end

  protected

  # Internal: Assign a SecureRandom key to the AssignmentInvitation
  # if it is not already set.
  #
  # Returns the key as a String
  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
