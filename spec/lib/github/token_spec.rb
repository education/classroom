# frozen_string_literal: true

require "rails_helper"

describe GitHub::Token do
  subject { described_class }

  let(:student) { classroom_student }

  describe "#scopes", :vcr do
    it "returns the scopes of the token in an array" do
      expect(described_class.scopes(student.token)).to be_kind_of(Array)
    end
  end

  describe "#expand_scopes", :vcr do
    it "converts scopes to their expanded form" do
      scope_list = ["user", "repo", "write:org"]
      expected_expanded = [
        "user", "read:user", "user:email", "user:follow",
        "repo", "repo:status", "repo_deployment", "public_repo", "repo:invite",
        "write:org", "read:org"
      ]

      expect(described_class.expand_scopes(scope_list)).to match_array(expected_expanded)
    end
  end

  describe "descendents" do
    scope_tree = {
      "admin:org" => {
        "write:org" => {
          "read:org" => {}
        }
      },
      "admin:public_key" => {
        "write:public_key" => {
          "read:public_key" => {}
        },
        "admin:obscure_key" => {
          "write:obscure_key" => {
            "read:obscure_key" => {
              "execute:obscure_key" => {}
            }
          }
        }
      },
      "gist" => {}
    }.freeze

    it "returns [] when the scope is the last child" do
      expect(subject.descendents("read:org", scope_tree)).to eq([])
    end

    it "returns a list of children when it is a middle child" do
      expect(subject.descendents("write:org", scope_tree)).to eq(["read:org"])
    end

    it "returns a list of children when it is a parent" do
      expect(subject.descendents("admin:org", scope_tree)).to eq(["write:org", "read:org"])
    end

    it "returns [] when the scope is childless" do
      expect(subject.descendents("gist", scope_tree)).to eq([])
    end

    it "returns children when the scope is a grandchild" do
      expect(subject.descendents("read:obscure_key", scope_tree)).to eq(["execute:obscure_key"])
    end

    it "returns grandchildren when the scope is a child" do
      expect(subject.descendents("write:obscure_key", scope_tree)).to eq(["read:obscure_key", "execute:obscure_key"])
    end
  end
end
