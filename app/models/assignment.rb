class Assignment < ActiveRecord::Base
  include GitHubPlan

  extend FriendlyId
  friendly_id :title, use: [:slugged, :finders]

  default_scope { where(deleted_at: nil) }

  has_one :assignment_invitation, dependent: :destroy, autosave: true

  has_many :assignment_repos, dependent: :destroy
  has_many :repo_accesses,    through:   :assignment_repos
  has_many :users,            through:   :repo_accesses

  belongs_to :creator, class_name: User
  belongs_to :organization

  validates :creator, presence: true

  validates :organization, presence: true

  validates :title, presence: true
  validates :title, uniqueness: { scope: :organization }
  validates :title, length: { maximum: 60 }

  validate :uniqueness_of_title_across_organization

  alias_attribute :invitation, :assignment_invitation

  # Public: Determine if the Assignment is private
  #
  # Example
  #
  #  assignment.public?
  #  # => true
  #
  # Returns a boolean
  def private?
    !public_repo
  end

  # Public: Determine if the Assignment is public
  #
  # Example
  #
  #  assignment.private?
  #  # => true
  #
  # Returns a boolean
  def public?
    public_repo
  end

  # Public: Determine if the Assignment has starter code
  #
  # Example
  #
  #  assignment.starter_code?
  #  # => true
  #
  # Returns if the starter_code_repo_id column is not NULL
  def starter_code?
    starter_code_repo_id.present?
  end

  private

  # Internal: Verify that there aren't any GroupAssignments in the
  # Assignments Organization that have the same title.
  #
  # This will add an error to the title column if there is a match
  def uniqueness_of_title_across_organization
    return unless GroupAssignment.where(slug: normalize_friendly_id(title), organization: organization).present?
    errors.add(:title, 'title is already in use for your organization')
  end
end
