class ExpandCauses < ActiveRecord::Migration
  def self.up
    add_column :causes, :full_description, :text
    add_column :causes, :substantiation, :text
    add_column :causes, :website_url, :string
    add_column :causes, :facebook_profile, :string
    add_column :causes, :youtube_url, :string
    add_column :causes, :originator_email, :string
    add_column :causes, :preselection_vote_count, :integer
    add_column :causes, :vote_count, :integer
    add_column :causes, :office, :string
    add_column :causes, :department, :string
    add_column :causes, :note, :text
  end

  def self.down
    remove_column :causes, :full_description
    remove_column :causes, :substantiation
    remove_column :causes, :website_url
    remove_column :causes, :facebook_profile
    remove_column :causes, :youtube_url
    remove_column :causes, :originator_email
    remove_column :causes, :preselection_vote_count
    remove_column :causes, :vote_count
    remove_column :causes, :office
    remove_column :causes, :department
    remove_column :causes, :note
  end
end
