# frozen_string_literal: true

require_relative 'support/vcr'
require 'securerandom'

FactoryGirl.define do
  factory :assignment do
    organization

    title        { "#{Faker::Company.name} Assignment" }
    slug         { title.parameterize                  }
    creator      { organization.users.first            }
  end

  factory :assignment_invitation do
    assignment
  end

  factory :assignment_repo do
    assignment
    user

    github_repo_id { rand(1..1_000_000) }
  end

  factory :group_assignment do
    organization

    title    { "#{Faker::Company.name} Group Assignment"     }
    slug     { title.parameterize                            }
    grouping { create(:grouping, organization: organization) }
    creator  { organization.users.first                      }
  end

  factory :group_assignment_invitation do
    group_assignment
  end

  factory :grouping do
    organization

    title { Faker::Company.name }
    slug  { title.parameterize  }
  end

  factory :organization do
    title      { "#{Faker::Company.name} Class" }
    github_id  { rand(1..1_000_000) }

    transient do
      users_count 1
    end

    after(:build) do |organization, evaluator|
      if evaluator.users.count < evaluator.users_count
        create_list(:user, evaluator.users_count, organizations: [organization])
      end
    end
  end

  factory :student_identifier do
    type
    organization
    user

    value { Faker::Lorem.word }
  end

  factory :student_identifier_type, aliases: [:type] do
    organization

    name         { Faker::Lorem.word     }
    description  { Faker::Lorem.sentence }
  end

  factory :user do
    uid    { rand(1..1_000_000) }
    token  { SecureRandom.hex(20) }

    factory :user_with_organizations do
      transient do
        organizations_count 5
      end

      after(:create) do |user, evaluator|
        create_list(:organization, evaluator.organizations_count, users: [user])
      end
    end
  end
end
